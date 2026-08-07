#include "GameLogic.h"
#include "Memory.h"
#import <UIKit/UIKit.h>

uint64_t GetMatchGame(uint64_t base) {
    if (base == 0) return 0;
    uint64_t facadeStatic = ReadPointer(base + OFFSET_GAMEFACADE);
    if (facadeStatic == 0) return 0;
    uint64_t facadeClass = ReadPointer(facadeStatic + 0x5C);
    if (facadeClass == 0) return 0;
    return ReadPointer(facadeClass + 0x0);
}

uint64_t GetLocalPlayer(uint64_t matchGame) {
    if (matchGame == 0) return 0;
    return ReadPointer(matchGame + 0x58);
}

uint64_t GetPawnObject(uint64_t player) {
    if (player == 0) return 0;
    return ReadPointer(player + 0x68);
}

Vector3 GetNodePosition(uint64_t pawn, uint32_t nodeOffset) {
    Vector3 pos(0, 0, 0);
    if (pawn == 0 || nodeOffset == 0) return pos;

    uint64_t nodePtr = ReadPointer(pawn + nodeOffset);
    if (nodePtr == 0) return pos;

    uint64_t transformPtr = ReadPointer(nodePtr + 0x10);
    if (transformPtr == 0) return pos;

    ReadMemory(transformPtr + 0x90, &pos, sizeof(Vector3));
    return pos;
}

bool GetIsDead(uint64_t player) {
    if (player == 0) return true;
    bool isDead = false;
    ReadMemory(player + 0x74, &isDead, sizeof(bool));
    return isDead;
}

std::vector<uint64_t> GetEnemyList(uint64_t matchGame) {
    std::vector<uint64_t> list;
    if (matchGame == 0) return list;

    uint64_t playerDict = ReadPointer(matchGame + 0x60);
    if (playerDict == 0) return list;

    uint64_t playerArray = ReadPointer(playerDict + 0x18);
    if (playerArray == 0) return list;

    int32_t count = 0;
    ReadMemory(playerArray + 0x18, &count, sizeof(count));

    if (count <= 0 || count > 100) return list;

    uint64_t itemsPtr = playerArray + 0x20;
    for (int i = 0; i < count; i++) {
        uint64_t player = ReadPointer(itemsPtr + (i * 8));
        if (player != 0) {
            list.push_back(player);
        }
    }

    return list;
}

Vector3 WorldToScreen(Vector3 worldPos) {
    Vector3 screenPos(0, 0, 0);
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    // Fallback simple screen projection
    screenPos.x = bounds.size.width / 2.0f;
    screenPos.y = bounds.size.height / 2.0f;
    screenPos.z = 1.0f;
    return screenPos;
}
