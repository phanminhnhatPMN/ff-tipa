#ifndef MEMORY_H
#define MEMORY_H

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <sys/sysctl.h>

pid_t GetGamePID(void);
uint64_t GetGameModuleBase(pid_t pid);
bool ReadMemory(pid_t pid, uint64_t address, void *buffer, size_t size);

template <typename T>
T ReadAddr(pid_t pid, uint64_t address) {
    T val = T();
    ReadMemory(pid, address, &val, sizeof(T));
    return val;
}

#endif
