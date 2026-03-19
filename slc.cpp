
#include <wchar.h>
#include <windows.h>
#include <winsvc.h>
#include <stdio.h>



SERVICE_STATUS_HANDLE g_ServiceStatusHandle = NULL;
SERVICE_STATUS g_ServiceStatus = {};
HANDLE g_ServiceStopEvent = NULL;

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv);
VOID WINAPI ServiceCtrlHandler(DWORD ctrl);
void RunChildExecutable(LPCTSTR executablePath);

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow) {
    WCHAR serviceName[] = L"screenlogger";
    SERVICE_TABLE_ENTRY ServiceTable[] = {
        { serviceName, (LPSERVICE_MAIN_FUNCTION)ServiceMain },
        { NULL, NULL }
    };

    StartServiceCtrlDispatcher(ServiceTable);
    return 0;
}

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv) {
    g_ServiceStatusHandle = RegisterServiceCtrlHandler(L"screenlogger", ServiceCtrlHandler);
    g_ServiceStatus.dwServiceType = SERVICE_WIN32;
    g_ServiceStatus.dwCurrentState = SERVICE_START_PENDING;
    g_ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP;

    // Notify that the service is started
    SetServiceStatus(g_ServiceStatusHandle, &g_ServiceStatus);
    
    g_ServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    g_ServiceStatus.dwCurrentState = SERVICE_RUNNING;
    SetServiceStatus(g_ServiceStatusHandle, &g_ServiceStatus);

    RunChildExecutable(L"C:\\Program Files(x86)\\Reliance Systems\\screenlogger\\screenlogger.exe");
    
    g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
    SetServiceStatus(g_ServiceStatusHandle, &g_ServiceStatus);
    
    if (g_ServiceStopEvent)
        CloseHandle(g_ServiceStopEvent);
}

VOID WINAPI ServiceCtrlHandler(DWORD ctrl) {
    if (ctrl == SERVICE_CONTROL_STOP) {
        g_ServiceStatus.dwCurrentState = SERVICE_STOP_PENDING;
        SetEvent(g_ServiceStopEvent);
        return;
    }
}

void RunChildExecutable(LPCTSTR executablePath) {
    STARTUPINFO si = {};
    PROCESS_INFORMATION pi = {};
    si.cb = sizeof(si);
    
    if (CreateProcess(executablePath, NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        // Wait for the process to complete
        WaitForSingleObject(pi.hProcess, INFINITE);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    }
}
