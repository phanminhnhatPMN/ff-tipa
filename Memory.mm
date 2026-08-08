#import "Memory.h"
#include <mach/mach_traps.h>
#include <mach-o/dyld_images.h>

extern "C" kern_return_t mach_vm_region(
    vm_map_t target_task,
    mach_vm_address_t *address,
    mach_vm_size_t *size,
    vm_region_flavor_t flavor,
    vm_region_info_t info,
    mach_msg_type_number_t *infoCnt,
    mach_port_t *object_name
);

extern "C" kern_return_t mach_vm_read_overwrite(
    vm_map_t target_task,
    mach_vm_address_t address,
    mach_vm_size_t size,
    mach_vm_address_t data,
    mach_vm_size_t *outsize
);

pid_t GetGamePID(void) {
    static const char* processNames[] = {"freefireth", "freefire", "FreeFire", "FF"};
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size = 0;
    
    if (sysctl(mib, 4, NULL, &size, NULL, 0) < 0) return -1;
    
    struct kinfo_proc *procs = (struct kinfo_proc *)malloc(size);
    if (!procs) return -1;
    
    if (sysctl(mib, 4, procs, &size, NULL, 0) < 0) {
        free(procs);
        return -1;
    }
    
    int count = (int)(size / sizeof(struct kinfo_proc));
    pid_t foundPid = -1;
    
    for (int i = 0; i < count; i++) {
        char *pName = procs[i].kp_proc.p_comm;
        for (int j = 0; j < 4; j++) {
            if (strcasecmp(pName, processNames[j]) == 0) {
                foundPid = procs[i].kp_proc.p_pid;
                break;
            }
        }
        if (foundPid != -1) break;
    }
    
    free(procs);
    return foundPid;
}

static task_t g_cachedTask = MACH_PORT_NULL;
static pid_t g_cachedPid = -1;

static task_t GetTaskForPid(pid_t pid) {
    if (pid <= 0) return MACH_PORT_NULL;
    if (g_cachedPid == pid && g_cachedTask != MACH_PORT_NULL && MACH_PORT_VALID(g_cachedTask)) {
        return g_cachedTask;
    }
    
    task_t task = MACH_PORT_NULL;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr == KERN_SUCCESS && MACH_PORT_VALID(task)) {
        g_cachedTask = task;
        g_cachedPid = pid;
        return task;
    }
    return MACH_PORT_NULL;
}

uint64_t GetGameModuleBase(pid_t pid) {
    if (pid <= 0) return 0;

    task_t task = GetTaskForPid(pid);
    if (task == MACH_PORT_NULL) return 0;

    mach_vm_address_t address = 0x100000000;
    mach_vm_size_t size = 0;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t objectName = MACH_PORT_NULL;

    while (mach_vm_region(task, &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &count, &objectName) == KERN_SUCCESS) {
        if (info.protection & VM_PROT_READ) {
            uint32_t magic = 0;
            mach_vm_size_t outSize = 0;
            if (mach_vm_read_overwrite(task, address, sizeof(magic), (mach_vm_address_t)&magic, &outSize) == KERN_SUCCESS) {
                if (magic == 0xFEEDFACF || magic == 0xFEEDFACE) { // MH_MAGIC_64 / MH_MAGIC
                    return (uint64_t)address;
                }
            }
        }
        address += size;
        if (address > 0x200000000) break;
    }

    return 0;
}

bool ReadMemory(pid_t pid, uint64_t address, void *buffer, size_t size) {
    if (pid <= 0 || address == 0 || buffer == NULL || size == 0) return false;

    task_t task = GetTaskForPid(pid);
    if (task == MACH_PORT_NULL) return false;

    mach_vm_size_t outSize = 0;
    kern_return_t kr = mach_vm_read_overwrite(task, (mach_vm_address_t)address, (mach_vm_size_t)size, (mach_vm_address_t)buffer, &outSize);
    return (kr == KERN_SUCCESS && outSize == size);
}

