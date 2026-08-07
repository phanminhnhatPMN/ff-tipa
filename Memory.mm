#include "Memory.h"
#include <strings.h>

#ifndef PROC_PIDPATHINFO_MAXSIZE
#define PROC_PIDPATHINFO_MAXSIZE 1024
#endif
#ifndef PROC_ALL_PIDS
#define PROC_ALL_PIDS 1
#endif

extern "C" {
    int proc_listpids(uint32_t type, uint32_t typeinfo, void *buffer, int buffersize);
    int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
}

static mach_port_t g_gameTask = 0;

static bool IsTargetProcess(const char *name) {
    if (!name) return false;
    if (strcasestr(name, "freefireth")) return true;
    if (strcasestr(name, "freefiremax")) return true;
    if (strcasestr(name, "freefire")) return true;
    if (strcasestr(name, "garena")) return true;
    if (strcasestr(name, "FFExt")) return true;
    if (strcasecmp(name, "ff") == 0) return true;
    return false;
}

pid_t GetGamePID(void) {
    // 1. Try proc_listpids & proc_pidpath
    int numPids = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    if (numPids > 0) {
        pid_t pids[2048];
        int bytesReturned = proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));
        int count = bytesReturned / sizeof(pid_t);

        for (int i = 0; i < count; i++) {
            pid_t pid = pids[i];
            if (pid <= 0) continue;

            char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
            if (proc_pidpath(pid, pathBuffer, sizeof(pathBuffer)) > 0) {
                if (IsTargetProcess(pathBuffer)) {
                    return pid;
                }
            }
        }
    }

    // 2. Fallback to sysctl KERN_PROC_ALL
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size;

    if (sysctl(mib, 4, NULL, &size, NULL, 0) == 0) {
        struct kinfo_proc *procs = (struct kinfo_proc *)malloc(size);
        if (procs) {
            if (sysctl(mib, 4, procs, &size, NULL, 0) == 0) {
                int count = (int)(size / sizeof(struct kinfo_proc));
                for (int i = 0; i < count; i++) {
                    char *name = procs[i].kp_proc.p_comm;
                    if (IsTargetProcess(name)) {
                        pid_t foundPID = procs[i].kp_proc.p_pid;
                        free(procs);
                        return foundPID;
                    }
                }
            }
            free(procs);
        }
    }

    return -1;
}

uint64_t GetGameModuleBase(pid_t pid) {
    if (pid <= 0) return 0;
    
    g_gameTask = 0;
    kern_return_t kr_task = task_for_pid(mach_task_self(), pid, &g_gameTask);
    if (kr_task != KERN_SUCCESS || g_gameTask == 0) return 0;

    vm_address_t address = 0;
    vm_size_t size = 0;
    uint32_t depth = 1;
    struct vm_region_submap_info_64 info;
    mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;

    while (1) {
        kern_return_t kr = vm_region_recurse_64(g_gameTask, &address, &size, &depth, (vm_region_recurse_info_t)&info, &count);
        if (kr != KERN_SUCCESS) break;

        if (info.is_submap) {
            depth++;
            continue;
        }

        uint32_t header[2];
        vm_size_t bytesRead = 0;
        if (vm_read_overwrite(g_gameTask, address, sizeof(header), (vm_address_t)header, &bytesRead) == KERN_SUCCESS) {
            if (header[0] == 0xFEEDFACF || header[0] == 0xFEEDFACE) { // MH_MAGIC_64 / MH_MAGIC
                return (uint64_t)address;
            }
        }

        address += size;
    }

    return 0;
}

bool ReadMemory(uint64_t address, void* buffer, size_t size) {
    if (address == 0 || buffer == NULL || size == 0) return false;
    
    if (g_gameTask == 0) {
        pid_t pid = GetGamePID();
        if (pid > 0) {
            task_for_pid(mach_task_self(), pid, &g_gameTask);
        }
    }

    if (g_gameTask == 0) return false;

    vm_size_t bytesRead = 0;
    kern_return_t kr = vm_read_overwrite(g_gameTask, (vm_address_t)address, size, (vm_address_t)buffer, &bytesRead);
    return (kr == KERN_SUCCESS && bytesRead == size);
}

uint64_t ReadPointer(uint64_t address) {
    uint64_t ptr = 0;
    if (ReadMemory(address, &ptr, sizeof(ptr))) {
        return ptr;
    }
    return 0;
}
