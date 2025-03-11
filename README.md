This is a rewrite of [Asleum's Moonsweeper](https://github.com/Asleum/moonsweeper) using different board generation logic and more modern OOP.

Universal Minesweeper generates Minesweeper games of any dimension.

Normal Minesweeper games are 2D objects embedded in 2D space, where we look up/down and left/right for mines. If we think of a 2D game as one "layer" of tiles, we can stack these layers to bring the game into the third dimension. Now, we can look up/down, left/right, and in/out; one direction for each dimension in our 3-dimensional world.

We can extend this idea and add another direction in which to look for mines, which we can call ana/kata. Like how we stacked 2D boards to create 3D boards, looking at the boards above and below for mines in the third dimension, we stack 3D boards to create 4D ones. Now, we look ana and kata (think of them as left/right in 4D) for mines around us in the 4th dimension.

To visualize this (graphics soon(tm)), picture three identical 3D boards side by side. Given a tile at position `(x, y, z)` in the middle board, we can look at the same position in the other two boards, which are one unit away in the 4th dimension. Expressing 4D position as `e`, the position in the middle board becomes `(e, x, y, z)`, and the two adjacent positions become `(e-1, x, y, z)` and `(e+1, x, y, z)`.