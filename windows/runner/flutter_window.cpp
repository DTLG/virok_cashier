#include "flutter_window.h"
#include <optional>
#include "flutter/generated_plugin_registrant.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>
#include <comdef.h> 
#include <string>
#include <stdio.h> 
#include <vector> 
#include <iomanip>
#include <sstream>
#include <mutex> // Додано для Thread Safety

// Підключення згенерованого заголовку (вже без #import)
#include "cashalotapi64.tlh" 
// using namespace CashaLotApi; 

ICashaLotApiAddinPtr gsCashaLotApi = NULL;
// Глобальний м'ютекс для захисту COM викликів
std::mutex apiMutex;

const CLSID CLSID_CashalotActual = {0x910038E1,0x38F5,0x449D,{0x87,0xF4,0x53,0xC2,0x8D,0x93,0x94,0x5E}};
std::string lastComError = "";

// --- ДОПОМІЖНІ ФУНКЦІЇ ---
#include <string>
#include <windows.h>

// Конвертація UTF-8 (від Flutter) -> Wide String (для Windows COM)
std::wstring Utf8ToWide(const std::string& str) {
    if (str.empty()) return std::wstring();
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

// Конвертація BSTR (від Windows) -> UTF-8 (для Flutter)
std::string BstrToUtf8(BSTR bstr) {
    if (!bstr) return "";
    int len = (int)SysStringLen(bstr);
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, bstr, len, NULL, 0, NULL, NULL);
    if (size_needed <= 0) return "";
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, bstr, len, &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

std::string BstrToUtf8(_bstr_t bstrWrapper) {
    return BstrToUtf8(bstrWrapper.GetBSTR());
}

// Конвертація double -> String ("15,65") - З КОМОЮ!
std::string DoubleToCurrencyString(double value) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(2) << value;
    std::string s = out.str();
    size_t pos = s.find('.');
    if (pos != std::string::npos) s[pos] = ',';
    return s;
}

// Функція ініціалізації API
bool InitCashalot() {
    if (gsCashaLotApi != NULL) return true;
    HRESULT hr = gsCashaLotApi.CreateInstance(CLSID_CashalotActual);
    if (FAILED(hr)) {
        char buf[256]; sprintf_s(buf, "HRESULT Error: 0x%08X", hr);
        lastComError = std::string(buf);
        return false;
    }
    return true;
}

// --- УНІВЕРСАЛЬНИЙ БЕЗПЕЧНИЙ ВИКЛИК COM ---
struct ComResult {
    bool success;
    std::string jsonVal;
    std::string error;
};

ComResult InvokeDispatchMethod(std::wstring methodName, std::vector<_variant_t> args) {
    // 1. БЛОКУВАННЯ ПОТОКУ (Thread Safety)
    std::lock_guard<std::mutex> lock(apiMutex);

    if (gsCashaLotApi == NULL) {
         if (!InitCashalot()) return {false, "", "API is null and failed to re-init"};
    }

    IDispatchPtr spDispatch;
    HRESULT hr = gsCashaLotApi->QueryInterface(IID_IDispatch, (void**)&spDispatch);
    if (FAILED(hr) || spDispatch == NULL) return {false, "", "Failed to get IDispatch"};

    DISPID dispid;
    LPOLESTR pMethodName = (LPOLESTR)methodName.c_str();
    hr = spDispatch->GetIDsOfNames(IID_NULL, &pMethodName, 1, LOCALE_USER_DEFAULT, &dispid);
    if (FAILED(hr)) return {false, "", "Method not found: " + BstrToUtf8(_bstr_t(methodName.c_str()))};

    DISPPARAMS params = { NULL, NULL, 0, 0 };
    std::vector<VARIANT> reversedArgs;
    int argCount = static_cast<int>(args.size());
    if (argCount > 0) {
        params.cArgs = (UINT)argCount;
        // Аргументи передаються в зворотному порядку для Invoke
        for (int i = argCount - 1; i >= 0; i--) reversedArgs.push_back(args[i]);
        params.rgvarg = reversedArgs.data();
    }

    _variant_t resultVar;
    // Використовуємо try/catch для захисту від Access Violation всередині DLL
    try {
        hr = spDispatch->Invoke(dispid, IID_NULL, LOCALE_USER_DEFAULT, DISPATCH_METHOD, &params, &resultVar, NULL, NULL);
    } catch (...) {
        return {false, "", "CRITICAL: Exception inside Cashalot DLL"};
    }

    if (FAILED(hr)) {
        char buf[256]; sprintf_s(buf, "Invoke Failed: 0x%08X", hr);
        return {false, "", std::string(buf)};
    }

    // Розбір результату (CashalotApiRetVal)
    if (resultVar.vt == VT_DISPATCH && resultVar.pdispVal != NULL) {
        IDispatchPtr pResultObj = resultVar.pdispVal;
        
        auto GetProp = [&](std::wstring p) -> _variant_t {
            DISPID id; LPOLESTR pn = (LPOLESTR)p.c_str();
            pResultObj->GetIDsOfNames(IID_NULL, &pn, 1, LOCALE_USER_DEFAULT, &id);
            _variant_t r; DISPPARAMS n = {NULL, NULL, 0, 0};
            pResultObj->Invoke(id, IID_NULL, LOCALE_USER_DEFAULT, DISPATCH_PROPERTYGET, &n, &r, NULL, NULL);
            return r;
        };
        return {(bool)GetProp(L"Return"), BstrToUtf8(_bstr_t(GetProp(L"JsonVal"))), ""};
    } 
    else if (resultVar.vt == VT_BOOL) {
        bool s = (bool)resultVar;
        return {s, s ? "{\"Ret\":true}" : "{\"Ret\":false}", ""};
    }
    return {false, "", "Unknown return type from COM"};
}


FlutterWindow::FlutterWindow(const flutter::DartProject& project) : project_(project) {}
FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) return false;
  
  // Ініціалізація COM для цього потоку
  CoInitialize(NULL);
  
  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) return false;

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "com.cashalot/api",
      &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler([&](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
        // Захист від падіння всього додатку
        try {
            if (!InitCashalot()) { 
                result->Error("INIT_ERROR", "Init Failed: " + lastComError); 
                return; 
            }

            const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

            // 1. setParameter
            if (call.method_name() == "setParameter") {
                auto name = std::get<std::string>(args->at(flutter::EncodableValue("name")));
                auto value = std::get<std::string>(args->at(flutter::EncodableValue("value")));
                
                // Використовуємо Utf8ToWide для коректного шляху/значення
                _variant_t res = gsCashaLotApi->SetParameter(
                    _bstr_t(Utf8ToWide(name).c_str()), 
                    _bstr_t(Utf8ToWide(value).c_str())
                );
                result->Success(flutter::EncodableValue(BstrToUtf8(_bstr_t(res)))); 
            } 
            
            // 2. getCurrentStatus
            else if (call.method_name() == "getCurrentStatus") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 // Використовуємо InvokeDispatchMethod для безпеки
                 ComResult res = InvokeDispatchMethod(L"GetCurrentStatus", { _variant_t(Utf8ToWide(fNum).c_str()) });
                 
                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // 3. openShift
            else if (call.method_name() == "openShift") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 ComResult res = InvokeDispatchMethod(L"OpenShift", { _variant_t(Utf8ToWide(fNum).c_str()) });
                 
                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // 4. closeShift
            else if (call.method_name() == "closeShift") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 if (fNum.empty()) { result->Error("INVALID_ARGS", "FiscalNum is empty"); return; }
                 
                 ComResult res = InvokeDispatchMethod(L"CloseShift", { _variant_t(Utf8ToWide(fNum).c_str()) });
                 
                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }
            
            // 5. printXReport
            else if (call.method_name() == "printXReport") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 // GetXReport має другий параметр IsShort (bool), передаємо false
                 ComResult res = InvokeDispatchMethod(L"GetXReport", { 
                     _variant_t(Utf8ToWide(fNum).c_str()), 
                     _variant_t(false) 
                 });

                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // 6. fiscalizeCheck (ВАЖЛИВО: Конвертація JSON з кирилицею)
            else if (call.method_name() == "fiscalizeCheck") {
                auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                auto goods = std::get<std::string>(args->at(flutter::EncodableValue("jsonGoods")));
                auto pay = std::get<std::string>(args->at(flutter::EncodableValue("jsonPay")));
                
                ComResult res = InvokeDispatchMethod(L"FiscalizeCheck", { 
                    _variant_t(Utf8ToWide(fNum).c_str()), 
                    _variant_t(Utf8ToWide(goods).c_str()), 
                    _variant_t(Utf8ToWide(pay).c_str())
                });
                
                if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                flutter::EncodableMap r;
                r[flutter::EncodableValue("success")] = res.success;
                r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                result->Success(r);
            }

            // 7. serviceInput
            else if (call.method_name() == "serviceInput") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 double amount = std::get<double>(args->at(flutter::EncodableValue("amount")));
                 std::string amountStr = DoubleToCurrencyString(amount);
                 
                 // Можна додати касира, якщо є в аргументах, але тут базовий виклик
                 // Якщо треба касир: додайте _variant_t(Utf8ToWide(cashier).c_str()) другим параметром
                 ComResult res = InvokeDispatchMethod(L"ServiceInput", { 
                     _variant_t(Utf8ToWide(fNum).c_str()), 
                     _variant_t(Utf8ToWide(amountStr).c_str()) 
                 });

                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // 8. serviceOutput
            else if (call.method_name() == "serviceOutput") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 double amount = std::get<double>(args->at(flutter::EncodableValue("amount")));
                 std::string amountStr = DoubleToCurrencyString(amount);

                 ComResult res = InvokeDispatchMethod(L"ServiceOutput", { 
                     _variant_t(Utf8ToWide(fNum).c_str()), 
                     _variant_t(Utf8ToWide(amountStr).c_str()) 
                 });

                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // --- payByPaymentCard (Оплата карткою) ---
            else if (call.method_name() == "payByPaymentCard") {
                 auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));
                 auto amount_it = args->find(flutter::EncodableValue("amount"));

                 if (fiscal_it != args->end() && amount_it != args->end()) {
                     std::string fiscalNum = std::get<std::string>(fiscal_it->second);
                     std::string amountStr = std::get<std::string>(amount_it->second);

                     // PayByPaymentCard(FiscalNum, Amount, OtherParams)
                     ComResult res = InvokeDispatchMethod(L"PayByPaymentCard", { 
                         _variant_t(Utf8ToWide(fiscalNum).c_str()), 
                         _variant_t(Utf8ToWide(amountStr).c_str()),
                         _variant_t(L"") 
                     });

                     if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                     flutter::EncodableMap response;
                     response[flutter::EncodableValue("success")] = res.success;
                     response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                     result->Success(response);
                 } else { result->Error("INVALID_ARGS", "Expected fiscalNum and amount"); }
            }
            
            // --- getPOSTerminalList (Список терміналів) ---
            else if (call.method_name() == "getPOSTerminalList") {
                 auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));

                 if (fiscal_it != args->end()) {
                     std::string fiscalNum = std::get<std::string>(fiscal_it->second);

                     // Використовуємо InvokeDispatchMethod для безпеки
                     ComResult res = InvokeDispatchMethod(L"GetPOSTerminalList", { 
                         _variant_t(Utf8ToWide(fiscalNum).c_str()) 
                     });

                     if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                     flutter::EncodableMap response;
                     response[flutter::EncodableValue("success")] = res.success;
                     response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                     result->Success(response);
                 } else { result->Error("INVALID_ARGS", "Expected fiscalNum"); }
            }

            // --- returnPaymentByCard (Повернення на терміналі) ---
            else if (call.method_name() == "returnPaymentByCard") {
                 auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));
                 auto amount_it = args->find(flutter::EncodableValue("amount"));
                 auto rrn_it = args->find(flutter::EncodableValue("rrn"));

                 if (fiscal_it != args->end() && amount_it != args->end() && rrn_it != args->end()) {
                     std::string fiscalNum = std::get<std::string>(fiscal_it->second);
                     std::string amountStr = std::get<std::string>(amount_it->second);
                     std::string rrnStr = std::get<std::string>(rrn_it->second);

                     ComResult res = InvokeDispatchMethod(L"ReturnPaymentByPaymentCard", { 
                         _variant_t(Utf8ToWide(fiscalNum).c_str()), 
                         _variant_t(Utf8ToWide(amountStr).c_str()),
                         _variant_t(Utf8ToWide(rrnStr).c_str()),
                         _variant_t(L"") 
                     });

                     if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                     flutter::EncodableMap response;
                     response[flutter::EncodableValue("success")] = res.success;
                     response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                     result->Success(response);
                 } else { result->Error("INVALID_ARGS", "Expected fiscalNum, amount, rrn"); }
            }

            // --- cancelPaymentByCard (Скасування транзакції) ---
            else if (call.method_name() == "cancelPaymentByCard") {
                 auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));
                 auto amount_it = args->find(flutter::EncodableValue("amount"));
                 auto invoice_it = args->find(flutter::EncodableValue("invoiceNum"));

                 if (fiscal_it != args->end() && amount_it != args->end() && invoice_it != args->end()) {
                     std::string fiscalNum = std::get<std::string>(fiscal_it->second);
                     std::string amountStr = std::get<std::string>(amount_it->second);
                     std::string invoiceStr = std::get<std::string>(invoice_it->second);

                     ComResult res = InvokeDispatchMethod(L"CancelPaymentByPaymentCard", { 
                         _variant_t(Utf8ToWide(fiscalNum).c_str()), 
                         _variant_t(Utf8ToWide(amountStr).c_str()),
                         _variant_t(Utf8ToWide(invoiceStr).c_str()),
                         _variant_t(L"") 
                     });

                     if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                     flutter::EncodableMap response;
                     response[flutter::EncodableValue("success")] = res.success;
                     response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                     result->Success(response);
                 } else { result->Error("INVALID_ARGS", "Expected fiscalNum, amount, invoiceNum"); }
            }

            // --- fiscalizeReturnCheck (Фіскалізація повернення) ---
            else if (call.method_name() == "fiscalizeReturnCheck") {
                auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));
                auto goods_it = args->find(flutter::EncodableValue("jsonGoods"));
                auto pay_it = args->find(flutter::EncodableValue("jsonPay"));
                auto return_receipt_it = args->find(flutter::EncodableValue("returnReceiptFiscalNum"));

                if (fiscal_it != args->end()) {
                    std::string fiscalNum = std::get<std::string>(fiscal_it->second);
                    std::string goods = std::get<std::string>(goods_it->second);
                    std::string pay = std::get<std::string>(pay_it->second);
                    std::string returnReceiptNum = std::get<std::string>(return_receipt_it->second);

                    ComResult res = InvokeDispatchMethod(L"FiscalizeReturnCheck", { 
                        _variant_t(Utf8ToWide(fiscalNum).c_str()),
                        _variant_t(Utf8ToWide(goods).c_str()),
                        _variant_t(Utf8ToWide(pay).c_str()),
                        _variant_t(Utf8ToWide(returnReceiptNum).c_str())
                    });

                    if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                    flutter::EncodableMap response;
                    response[flutter::EncodableValue("success")] = res.success;
                    response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                    result->Success(response);
                } else { result->Error("INVALID_ARGS", "Args missing"); }
            }

            else if (call.method_name() == "getVersion") {
                _variant_t varVer = gsCashaLotApi->GetVersion();
                result->Success(flutter::EncodableValue(BstrToUtf8(_bstr_t(varVer))));
            }
            else { result->NotImplemented(); }

        } catch (_com_error& e) {
             char buf[1024]; sprintf_s(buf, "HRESULT: 0x%08X", e.Error());
             result->Error("COM_ERROR", buf);
        } catch (...) { result->Error("UNKNOWN_ERROR", "Crash inside C++ handler"); }
  });

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();
  return true;
}


void FlutterWindow::OnDestroy() {
  // Звільняємо ресурси при закритті вікна
  std::lock_guard<std::mutex> lock(apiMutex);
  if (gsCashaLotApi != NULL) {
      gsCashaLotApi.Release();
      gsCashaLotApi = NULL;
  }
  CoUninitialize();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}