#import "GameLogic.h"
#import "Memory.h"

static uint64_t g_gameFacadeOffset = 0xC012848;

void SetGameFacadeOffset(uint64_t offset) {
    if (offset > 0) {
        g_gameFacadeOffset = offset;
    }
}

uint64_t GetMatchGame(uint64_t base) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || base == 0) return 0;

    uint64_t facadePtr = base + g_gameFacadeOffset;
    uint64_t staticFields = ReadAddr<uint64_t>(pid, facadePtr);
    if (staticFields == 0) return 0;

    // Offset 0x8: public static MatchGame CurrentMatchGame;
    uint64_t matchGame = ReadAddr<uint64_t>(pid, staticFields + 0x8);
    if (matchGame == 0) {
        // Fallback offset 0x0: public static BaseGame CurrentGame;
        matchGame = ReadAddr<uint64_t>(pid, staticFields + 0x0);
    }
    return matchGame;
}

uint64_t GetMatch(uint64_t matchGame) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || matchGame == 0) return 0;
    return ReadAddr<uint64_t>(pid, matchGame + 0x60);
}

uint64_t GetLocalPlayer(uint64_t matchGame) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || matchGame == 0) return 0;
    return ReadAddr<uint64_t>(pid, matchGame + 0x88);
}

uint64_t GetCameraMain(uint64_t matchGame) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || matchGame == 0) return 0;
    uint64_t cameraMgr = ReadAddr<uint64_t>(pid, matchGame + 0x78);
    if (cameraMgr == 0) return 0;
    return ReadAddr<uint64_t>(pid, cameraMgr + 0x48);
}

void GetViewMatrix(uint64_t cameraMain, float *matrixOut) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || cameraMain == 0 || matrixOut == NULL) return;
    ReadMemory(pid, cameraMain + 0x2D0, matrixOut, sizeof(float) * 16);
}

uint64_t GetPawnObject(uint64_t player) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || player == 0) return 0;
    return ReadAddr<uint64_t>(pid, player + 0xB0);
}

Vector3 GetNodePosition(uint64_t pawn, uint32_t nodeOffset) {
    pid_t pid = GetGamePID();
    Vector3 pos(0, 0, 0);
    if (pid <= 0 || pawn == 0 || nodeOffset == 0) return pos;

    uint64_t transformNode = ReadAddr<uint64_t>(pid, pawn + nodeOffset);
    if (transformNode == 0) return pos;

    pos.x = ReadAddr<float>(pid, transformNode + 0x90);
    pos.y = ReadAddr<float>(pid, transformNode + 0x94);
    pos.z = ReadAddr<float>(pid, transformNode + 0x98);

    return pos;
}

bool GetIsDead(uint64_t player) {
    pid_t pid = GetGamePID();
    if (pid <= 0 || player == 0) return true;
    uint32_t isDead = ReadAddr<uint32_t>(pid, player + 0x6C);
    return (isDead != 0);
}

std::vector<uint64_t> GetEnemyList(uint64_t matchGame) {
    std::vector<uint64_t> list;
    pid_t pid = GetGamePID();
    if (pid <= 0 || matchGame == 0) return list;

    uint64_t playerDict = ReadAddr<uint64_t>(pid, matchGame + 0x90);
    if (playerDict == 0) return list;

    uint64_t valuesPtr = ReadAddr<uint64_t>(pid, playerDict + 0x18);
    if (valuesPtr == 0) return list;

    uint32_t count = ReadAddr<uint32_t>(pid, playerDict + 0x20);
    if (count > 100) count = 100;

    for (uint32_t i = 0; i < count; i++) {
        uint64_t player = ReadAddr<uint64_t>(pid, valuesPtr + 0x20 + (i * 0x8));
        if (player != 0) {
            list.push_back(player);
        }
    }
    return list;
}

Vector3 WorldToScreen(Vector3 obj, float *matrix, float screenWidth, float screenHeight) {
    Vector3 out(-1, -1, -1);
    if (matrix == NULL) return out;

    float w = matrix[3] * obj.x + matrix[7] * obj.y + matrix[11] * obj.z + matrix[15];
    if (w < 0.01f) return out;

    float x = matrix[0] * obj.x + matrix[4] * obj.y + matrix[8] * obj.z + matrix[12];
    float y = matrix[1] * obj.x + matrix[5] * obj.y + matrix[9] * obj.z + matrix[13];

    float ndcX = x / w;
    float ndcY = y / w;

    out.x = (screenWidth / 2.0f) * (1.0f + ndcX);
    out.y = (screenHeight / 2.0f) * (1.0f - ndcY);
    out.z = w;

    return out;
}
