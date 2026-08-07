#include "Memory.h"
#include <strings.h>

static mach_port_t g_gameTask = 0;

pid_t GetGamePID(void) {
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size;

    if (sysctl(mib, 4, NULL, &size, NULL, 0) < 0) return -1;

    struct kinfo_proc *procs = (struct kinfo_proc *)malloc(size);
    if (!procs) return -1;

    if (sysctl(mib, 4, procs, &size, NULL, 0) < 0) {
        free(procs);
        return -1;
    }

    int count = (int)(size / sizeof(struct kinfo_proc));
    pid_t foundPID = -1;

    for (int i = 0; i < count; i++) {
        char *name = procs[i].kp_proc.p_comm;
        if (strcasestr(name, "freefire") || strcasestr(name, "ff")) {
            foundPID = procs[i].kp_proc.p_pid;
            break;
        }
    }

    free(procs);
    return foundPID;
}

uint64_t GetGameModuleBase(pid_t pid) {
    if (pid <= 0) return 0;
    
    if (g_gameTask == 0) {
        task_for_pid(mach_task_self(), pid, &g_gameTask);
    }
    
    if (g_gameTask == 0) return 0;

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
            if (header[0] == MH_MAGIC_64) {
                return address;
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
