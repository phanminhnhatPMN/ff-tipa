#ifndef GAMELOGIC_H
#define GAMELOGIC_H

#import <Foundation/Foundation.h>
#include <vector>

struct Vector3 {
    float x, y, z;

    Vector3() : x(0), y(0), z(0) {}
    Vector3(float x, float y, float z) : x(x), y(y), z(z) {}

    static float Distance(Vector3 a, Vector3 b) {
        float dx = a.x - b.x;
        float dy = a.y - b.y;
        float dz = a.z - b.z;
        return sqrtf(dx * dx + dy * dy + dz * dz);
    }
};

struct Quaternion {
    float x, y, z, w;
};

#define OFFSET_GAMEFACADE 0xC012848

uint64_t GetMatchGame(uint64_t base);
uint64_t GetMatch(uint64_t matchGame);
uint64_t GetLocalPlayer(uint64_t match);
uint64_t GetCameraMain(uint64_t matchGame);
void GetViewMatrix(uint64_t cameraMain, float *matrixOut);
uint64_t GetPawnObject(uint64_t player);
Vector3 GetNodePosition(uint64_t pawn, uint32_t nodeOffset);
bool GetIsDead(uint64_t player);
std::vector<uint64_t> GetEnemyList(uint64_t matchGame);
Vector3 WorldToScreen(Vector3 obj, float *matrix, float screenWidth, float screenHeight);

#endif
