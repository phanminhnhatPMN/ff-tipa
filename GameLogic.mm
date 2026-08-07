#include "GameLogic.h"
#include "Memory.h"
#import <UIKit/UIKit.h>

static uint64_t g_overrideOffset = 0xC012848;

void SetGameFacadeOffset(uint64_t offset) {
    g_overrideOffset = offset;
}

uint64_t GetMatchGame(uint64_t base) {
    if (base == 0) return 0;
    
    uint64_t typeInfo = ReadPointer(base + g_overrideOffset);
    if (typeInfo == 0) typeInfo = ReadPointer(base + 0xC012848);

    if (typeInfo > 0) {
        uint64_t staticFields = ReadPointer(typeInfo + 0xB8);
        if (staticFields > 0) {
            // CurrentMatchGame is at staticFields + 0x8
            uint64_t matchGame = ReadPointer(staticFields + 0x8);
            if (matchGame > 0) return matchGame;
            
            // Fallback to CurrentGame at staticFields + 0x0 if 0x8 is 0
            matchGame = ReadPointer(staticFields + 0x0);
            if (matchGame > 0) return matchGame;
        }
    }

    return 0;
}

uint64_t GetMatch(uint64_t matchGame) {
    if (matchGame == 0) return 0;
    return ReadPointer(matchGame + 0x90);
}

uint64_t GetLocalPlayer(uint64_t matchGame) {
    if (matchGame == 0) return 0;
    uint64_t match = ReadPointer(matchGame + 0x90);
    uint64_t lp = ReadPointer(match > 0 ? (match + 0x58) : (matchGame + 0x58));
    if (lp == 0) lp = ReadPointer(matchGame + 0x58);
    return lp;
}

uint64_t GetCameraMain(uint64_t matchGame) {
    if (matchGame == 0) return 0;
    uint64_t cameraManager = ReadPointer(matchGame + 0xD8);
    if (cameraManager == 0) cameraManager = ReadPointer(matchGame + 0xD0);
    if (cameraManager == 0) return 0;
    return ReadPointer(cameraManager + 0x18);
}

void GetViewMatrix(uint64_t cameraMain, float *matrixOut) {
    if (cameraMain == 0 || matrixOut == NULL) return;
    uint64_t v1 = ReadPointer(cameraMain + 0x10);
    if (v1 == 0) v1 = cameraMain;
    for (int i = 0; i < 16; i++) {
        ReadMemory(v1 + 0xD8 + (i * 0x4), &matrixOut[i], sizeof(float));
    }
}

uint64_t GetPawnObject(uint64_t player) {
    if (player == 0) return 0;
    uint64_t pawn = ReadPointer(player + 0x68);
    return (pawn != 0) ? pawn : player;
}

struct TMatrix {
    struct { float x, y, z, w; } position;
    struct { float x, y, z, w; } rotation;
    struct { float x, y, z, w; } scale;
};

Vector3 GetNodePosition(uint64_t pawn, uint32_t nodeOffset) {
    Vector3 result(0, 0, 0);
    if (pawn == 0 || nodeOffset == 0) return result;

    uint64_t bodyPart = ReadPointer(pawn + nodeOffset);
    if (bodyPart == 0) return result;

    uint64_t transObj2 = ReadPointer(bodyPart + 0x10);
    if (transObj2 == 0) {
        ReadMemory(bodyPart + 0x90, &result, sizeof(Vector3));
        return result;
    }

    uint64_t transObj = ReadPointer(transObj2 + 0x10);
    if (transObj == 0) {
        ReadMemory(transObj2 + 0x90, &result, sizeof(Vector3));
        return result;
    }

    uint64_t matrix = ReadPointer(transObj + 0x38);
    uint64_t index = ReadPointer(transObj + 0x40);
    if (matrix == 0) {
        ReadMemory(transObj + 0x90, &result, sizeof(Vector3));
        return result;
    }

    uint64_t matrix_list = ReadPointer(matrix + 0x18);
    uint64_t matrix_indices = ReadPointer(matrix + 0x20);
    if (matrix_list == 0 || matrix_indices == 0) return result;

    TMatrix initMatrix;
    ReadMemory(matrix_list + sizeof(TMatrix) * index, &initMatrix, sizeof(TMatrix));
    result.x = initMatrix.position.x;
    result.y = initMatrix.position.y;
    result.z = initMatrix.position.z;

    int transformIndex = 0;
    ReadMemory(matrix_indices + sizeof(int) * index, &transformIndex, sizeof(transformIndex));

    int depth = 0;
    while (transformIndex >= 0 && depth < 100) {
        TMatrix tMatrix;
        ReadMemory(matrix_list + sizeof(TMatrix) * transformIndex, &tMatrix, sizeof(TMatrix));

        float rotX = tMatrix.rotation.x;
        float rotY = tMatrix.rotation.y;
        float rotZ = tMatrix.rotation.z;
        float rotW = tMatrix.rotation.w;

        float scaleX = result.x * tMatrix.scale.x;
        float scaleY = result.y * tMatrix.scale.y;
        float scaleZ = result.z * tMatrix.scale.z;

        result.x = tMatrix.position.x + scaleX +
                    (scaleX * ((rotY * rotY * -2.0f) - (rotZ * rotZ * 2.0f))) +
                    (scaleY * ((rotW * rotZ * -2.0f) - (rotY * rotX * -2.0f))) +
                    (scaleZ * ((rotZ * rotX * 2.0f) - (rotW * rotY * -2.0f)));
        result.y = tMatrix.position.y + scaleY +
                    (scaleX * ((rotX * rotY * 2.0f) - (rotW * rotZ * -2.0f))) +
                    (scaleY * ((rotZ * rotZ * -2.0f) - (rotX * rotX * 2.0f))) +
                    (scaleZ * ((rotW * rotX * -2.0f) - (rotZ * rotY * -2.0f)));
        result.z = tMatrix.position.z + scaleZ +
                    (scaleX * ((rotW * rotY * -2.0f) - (rotX * rotZ * -2.0f))) +
                    (scaleY * ((rotY * rotZ * 2.0f) - (rotW * rotX * -2.0f))) +
                    (scaleZ * ((rotX * rotX * -2.0f) - (rotY * rotY * 2.0f)));

        int nextIndex = -1;
        ReadMemory(matrix_indices + sizeof(int) * transformIndex, &nextIndex, sizeof(nextIndex));
        if (nextIndex == transformIndex) break;
        transformIndex = nextIndex;
        depth++;
    }

    return result;
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
    if (playerDict == 0) playerDict = ReadPointer(matchGame + 0x58);
    if (playerDict == 0) return list;

    uint64_t playerArray = ReadPointer(playerDict + 0x18);
    if (playerArray == 0) playerArray = playerDict;
    if (playerArray == 0) return list;

    int32_t count = 0;
    ReadMemory(playerArray + 0x18, &count, sizeof(count));
    if (count <= 0 || count > 100) {
        ReadMemory(playerArray + 0x10, &count, sizeof(count));
    }

    if (count <= 0 || count > 100) return list;

    uint64_t itemsPtr = ReadPointer(playerArray + 0x10);
    if (itemsPtr == 0) itemsPtr = playerArray + 0x20;

    for (int i = 0; i < count; i++) {
        uint64_t player = ReadPointer(itemsPtr + (i * 8));
        if (player != 0) {
            list.push_back(player);
        }
    }

    return list;
}

Vector3 WorldToScreen(Vector3 obj, float *matrix, float screenWidth, float screenHeight) {
    Vector3 screen(0, 0, 0);
    if (matrix == NULL) return screen;

    float w = matrix[3] * obj.x + matrix[7] * obj.y + matrix[11] * obj.z + matrix[15];
    if (w < 0.1f) return screen;

    float x = (screenWidth / 2.0f) + (matrix[0] * obj.x + matrix[4] * obj.y + matrix[8] * obj.z + matrix[12]) / w * (screenWidth / 2.0f);
    float y = (screenHeight / 2.0f) - (matrix[1] * obj.x + matrix[5] * obj.y + matrix[9] * obj.z + matrix[13]) / w * (screenHeight / 2.0f);

    screen.x = x;
    screen.y = y;
    screen.z = w;
    return screen;
}
