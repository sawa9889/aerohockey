# Aerohockey

Play it here: https://saviorium.itch.io/aerohockey

Multiplayer aerohockey game for 2 players on LOVE2D. Made mainly to test networking.

### Features:
- Seamless netplay with rollback netcode
- Replays can be saved
- Multiple spectators can join and watch active game

To play, you would need a dedicated IP and port-forwarding, or to be in a local network. No singleplayer mode with bots unfortunately.

### How it works

Networking uses udp socket (netcode/network_thread.lua). The game uses rollback netcode, inspired by GGPO. (network/network_game.lua)
The game is deterministic, only player inputs are transferred over the network, but that's enough to recreate state of the game.
You can save and load states of the game. Every frame is numbered, and the game works on constant rate (it not depends on dt).
On local machine, all your inputs are shown immediately (actually, after 3 frames of constant delay) to ensure good controls.

When player receives inputs from another player, they are put in the table and the game rolls back to that moment. If there are none inputs from the opponent, they are predicted untill confirmed. After rollback, the state of the game is simulated again to current frame and if the position was predicted wrong, opponent or the ball is teleported to the new correct place. Usually, predictions are correct and most problems on network are unnoticeable for players

There is a system to synchronize the frame on each player's game. It works a bit different from GGPO. On every input packet, the game sends the last confirmed local frame (frame that the opponent got from you), and currently shown frame (frame that was on opponent's screen on that moment). You can use that information to calculate time of round trip between players and how much you are ahead of your opponent.

### Libraries and assets

- [LÖVE 11.3](https://love2d.org/)
- [hump](https://github.com/vrld/hump) - for classes, gamestates, vectors
- [peachy](https://github.com/josh-perry/peachy) - for animations
- [HC](https://github.com/vrld/HC) - collision library
- Uses bits of engine from our own [engine](https://github.com/Saviorium/platformer-framework)
- Our assets (sounds and images) are under the [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) license
- Fonts: [m3x6](https://managore.itch.io/m3x6), [7_digit_font](https://www.fontspace.com/cursed-timer-ulil-font-f29411)