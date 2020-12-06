// Import SDL2 and SDL_image
// Both work with Emscripten
import bindbc.sdl;
import bindbc.sdl.image;
//import core.stdc.stdio : printf; // printf works in Emscripten, too

// Function declarations for the main loop
alias em_arg_callback_func = extern(C) void function(void*) @nogc nothrow;
extern(C) void emscripten_set_main_loop_arg(em_arg_callback_func func, void *arg, int fps, int simulate_infinite_loop) @nogc nothrow;
extern(C) void emscripten_cancel_main_loop() @nogc nothrow;
extern(C):
// Log output
void logError(size_t line = __LINE__)() @nogc nothrow {
   //printf("%d:%s\n", line, SDL_GetError());
}

struct MainLoopArguments {
    SDL_Renderer* renderer;
    SDL_Texture* texture;
}

// Language features restricted with @nogc and nothrow
extern(C) int main(int argc, const char** argv) @nogc nothrow {
    // Initialise SDL
    if(SDL_Init(SDL_INIT_VIDEO) != 0) {
        logError();
        return -1;
    }
    scope(exit) SDL_Quit();

    // Initialise SDL_image (with PNG support)
    if(IMG_Init(IMG_INIT_PNG) != IMG_INIT_PNG) {
        logError();
        return -1;
    }
    scope(exit) IMG_Quit();

    // Make the window and its renderer
    SDL_Window* window;
    SDL_Renderer* renderer;
    if(SDL_CreateWindowAndRenderer(640, 480, SDL_WINDOW_SHOWN, &window, &renderer) != 0) {
        logError();
        return -1;
    }
    scope(exit) {
        SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    }

    // Load image file
    auto dman = IMG_Load("images/dman.png");
    if(!dman) {
        logError();
        return -1;
    }
    scope(exit) SDL_FreeSurface(dman);

    // Make a texture from the image
    auto texture = SDL_CreateTextureFromSurface(renderer, dman);
    if(!texture) {
        logError();
        return -1;
    }
    scope(exit) SDL_DestroyTexture(texture);

    // Start the image main loop
    auto arguments = MainLoopArguments(renderer, texture);
    emscripten_set_main_loop_arg(&mainLoop, &arguments, 60, 1);
    return 0;
}

extern(C) void mainLoop(void* p) @nogc nothrow {
    // Get arguments
    auto arguments = cast(MainLoopArguments*) p;
    auto renderer = arguments.renderer;
    auto texture = arguments.texture;

    // Clear background
    SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0x00);
    SDL_RenderClear(renderer);

    // Texture image
    SDL_RenderCopy(renderer, texture, null, null);
    SDL_RenderPresent(renderer);

    // End of loop iteration
    emscripten_cancel_main_loop();
}