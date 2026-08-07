#ifndef MEMORY_H
#define MEMORY_H

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <sys/sysctl.h>
#include <vector>
#include <string>

pid_t GetGamePID(void);
uint64_t GetGameModuleBase(pid_t pid);
bool ReadMemory(uint64_t address, void* buffer, size_t size);
uint64_t ReadPointer(uint64_t address);

#endif
