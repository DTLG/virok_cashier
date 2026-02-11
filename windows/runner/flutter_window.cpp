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

#import "D:\\Cashalot\\CashalotApi64.dll" no_namespace named_guids

ICashaLotApiAddinPtr gsCashaLotApi = NULL;
const CLSID CLSID_CashalotActual = {0x910038E1,0x38F5,0x449D,{0x87,0xF4,0x53,0xC2,0x8D,0x93,0x94,0x5E}};
std::string lastComError = "";

// --- ДОПОМІЖНІ ФУНКЦІЇ ---

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
    
    // Замінюємо крапку на кому, бо Cashalot (і Windows укр) хоче кому
    size_t pos = s.find('.');
    if (pos != std::string::npos) {
        s[pos] = ',';
    }
    return s;
}

// --- УНІВЕРСАЛЬНИЙ ВИКЛИК (ТІЛЬКИ ДЛЯ ПРОБЛЕМНИХ МЕТОДІВ) ---
struct ComResult {
    bool success;
    std::string jsonVal;
    std::string error;
};

ComResult InvokeDispatchMethod(std::wstring methodName, std::vector<_variant_t> args) {
    if (gsCashaLotApi == NULL) return {false, "", "API is null"};

    IDispatchPtr spDispatch;
    HRESULT hr = gsCashaLotApi->QueryInterface(IID_IDispatch, (void**)&spDispatch);
    if (FAILED(hr) || spDispatch == NULL) return {false, "", "Failed to get IDispatch"};

    DISPID dispid;
    LPOLESTR pMethodName = (LPOLESTR)methodName.c_str();
    hr = spDispatch->GetIDsOfNames(IID_NULL, &pMethodName, 1, LOCALE_USER_DEFAULT, &dispid);
    if (FAILED(hr)) return {false, "", "Method not found"};

    DISPPARAMS params = { NULL, NULL, 0, 0 };
    std::vector<VARIANT> reversedArgs;
    int argCount = static_cast<int>(args.size());
    if (argCount > 0) {
        params.cArgs = (UINT)argCount;
        for (int i = argCount - 1; i >= 0; i--) reversedArgs.push_back(args[i]);
        params.rgvarg = reversedArgs.data();
    }

    _variant_t resultVar;
    hr = spDispatch->Invoke(dispid, IID_NULL, LOCALE_USER_DEFAULT, DISPATCH_METHOD, &params, &resultVar, NULL, NULL);
    if (FAILED(hr)) {
        char buf[256]; sprintf_s(buf, "Invoke Failed: 0x%08X", hr);
        return {false, "", std::string(buf)};
    }

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
    return {false, "", "Unknown return type"};
}

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

FlutterWindow::FlutterWindow(const flutter::DartProject& project) : project_(project) {}
FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) return false;
  CoInitialize(NULL);
  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) return false;

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "com.cashalot/api",
      &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler([](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
        if (!InitCashalot()) { result->Error("INIT_ERROR", "Init Failed: " + lastComError); return; }

        try {
            const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

            // 1. setParameter (ПРЯМИЙ ВИКЛИК - СТАБІЛЬНО)
            if (call.method_name() == "setParameter") {
                auto name = std::get<std::string>(args->at(flutter::EncodableValue("name")));
                auto value = std::get<std::string>(args->at(flutter::EncodableValue("value")));
                _variant_t res = gsCashaLotApi->SetParameter(_bstr_t(name.c_str()), _bstr_t(value.c_str()));
                result->Success(flutter::EncodableValue(BstrToUtf8(_bstr_t(res)))); 
            } 
            
            // 2. getCurrentStatus (ПРЯМИЙ ВИКЛИК - СТАБІЛЬНО)
            else if (call.method_name() == "getCurrentStatus") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 ICashalotApiRetValPtr ret = gsCashaLotApi->GetCurrentStatus(_bstr_t(fNum.c_str()));
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = (bool)ret->Return;
                 r[flutter::EncodableValue("jsonVal")] = BstrToUtf8(ret->JsonVal);
                 result->Success(r);
            }

            // 3. openShift (ПРЯМИЙ ВИКЛИК)
            // Виправлена помилка компіляції: передаємо _bstr_t напряму
            else if (call.method_name() == "openShift") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 ICashalotApiRetValPtr ret = gsCashaLotApi->OpenShift(_bstr_t(fNum.c_str()));
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = (bool)ret->Return;
                 r[flutter::EncodableValue("jsonVal")] = BstrToUtf8(ret->JsonVal);
                 result->Success(r);
            }

            // 4. closeShift (ПРЯМИЙ ВИКЛИК)
            else if (call.method_name() == "closeShift") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 ICashalotApiRetValPtr ret = gsCashaLotApi->CloseShift(_bstr_t(fNum.c_str()));
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = (bool)ret->Return;
                 r[flutter::EncodableValue("jsonVal")] = BstrToUtf8(ret->JsonVal);
                 result->Success(r);
            }
            
            // 5. printXReport (ПРЯМИЙ ВИКЛИК)
            else if (call.method_name() == "printXReport") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 ICashalotApiRetValPtr ret = gsCashaLotApi->GetXReport(_bstr_t(fNum.c_str()), false);
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = (bool)ret->Return;
                 r[flutter::EncodableValue("jsonVal")] = BstrToUtf8(ret->JsonVal);
                 result->Success(r);
            }

            // 6. fiscalizeCheck (ПРЯМИЙ ВИКЛИК)
            else if (call.method_name() == "fiscalizeCheck") {
                auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                auto goods = std::get<std::string>(args->at(flutter::EncodableValue("jsonGoods")));
                auto pay = std::get<std::string>(args->at(flutter::EncodableValue("jsonPay")));
                
                ICashalotApiRetValPtr ret = gsCashaLotApi->FiscalizeCheck(
                    _bstr_t(fNum.c_str()), _bstr_t(goods.c_str()), _bstr_t(pay.c_str()));
                
                flutter::EncodableMap r;
                r[flutter::EncodableValue("success")] = (bool)ret->Return;
                r[flutter::EncodableValue("jsonVal")] = BstrToUtf8(ret->JsonVal);
                result->Success(r);
            }

            // 7. serviceInput (!!! РУЧНИЙ ВИКЛИК - БО ПОТРІБНА КОНВЕРТАЦІЯ ТИПІВ !!!)
            else if (call.method_name() == "serviceInput") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 double amount = std::get<double>(args->at(flutter::EncodableValue("amount")));
                 std::string amountStr = DoubleToCurrencyString(amount);

                 // Використовуємо InvokeDispatchMethod бо тут треба передати String, а не double
                 ComResult res = InvokeDispatchMethod(L"ServiceInput", { 
                     _bstr_t(fNum.c_str()), 
                     _bstr_t(amountStr.c_str()) 
                 });

                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // 8. serviceOutput (!!! РУЧНИЙ ВИКЛИК !!!)
            else if (call.method_name() == "serviceOutput") {
                 auto fNum = std::get<std::string>(args->at(flutter::EncodableValue("fiscalNum")));
                 double amount = std::get<double>(args->at(flutter::EncodableValue("amount")));
                 std::string amountStr = DoubleToCurrencyString(amount);

                 ComResult res = InvokeDispatchMethod(L"ServiceOutput", { 
                     _bstr_t(fNum.c_str()), 
                     _bstr_t(amountStr.c_str()) 
                 });

                 if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }
                 flutter::EncodableMap r;
                 r[flutter::EncodableValue("success")] = res.success;
                 r[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                 result->Success(r);
            }

            // --- payByPaymentCard (Оплата карткою через Cashalot) ---
            else if (call.method_name() == "payByPaymentCard") {
                 // Використовуємо існуючий args (не оголошуємо знову!)
                 auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));
                 auto amount_it = args->find(flutter::EncodableValue("amount"));

                 if (fiscal_it != args->end() && amount_it != args->end()) {
                     std::string fiscalNum = std::get<std::string>(fiscal_it->second);
                     std::string amountStr = std::get<std::string>(amount_it->second);

                     // Викликаємо COM метод: PayByPaymentCard(FiscalNum, Amount, OtherParams)
                     ComResult res = InvokeDispatchMethod(L"PayByPaymentCard", { 
                         _bstr_t(fiscalNum.c_str()), 
                         _bstr_t(amountStr.c_str()),
                         _bstr_t("") // OtherParam - зарезервований, передаємо пустий
                     });

                     if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }

                     flutter::EncodableMap response;
                     response[flutter::EncodableValue("success")] = res.success;
                     response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                     result->Success(response);
                 } else { result->Error("INVALID_ARGS", "Expected fiscalNum and amount"); }
            }
            
            // --- getPOSTerminalList (Отримання списку терміналів) ---
            else if (call.method_name() == "getPOSTerminalList") {
                 // ВИДАЛІТЬ ЦЕЙ РЯДОК: const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
                 
                 // Використовуємо вже існуючий args
                 auto fiscal_it = args->find(flutter::EncodableValue("fiscalNum"));

                 if (fiscal_it != args->end()) {
                     std::string fiscalNum = std::get<std::string>(fiscal_it->second);

                     ComResult res = InvokeDispatchMethod(L"GetPOSTerminalList", { 
                         _bstr_t(fiscalNum.c_str()) 
                     });

                     if (!res.error.empty()) { result->Error("COM_ERROR", res.error); return; }

                     flutter::EncodableMap response;
                     response[flutter::EncodableValue("success")] = res.success;
                     response[flutter::EncodableValue("jsonVal")] = res.jsonVal;
                     result->Success(response);
                 } else { result->Error("INVALID_ARGS", "Expected fiscalNum"); }
            }
            // ... (інші методи)
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