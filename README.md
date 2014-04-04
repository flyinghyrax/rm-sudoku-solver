## Rainmeter Sudoku Solver ##
Preview and download [on DeviantArt](http://flyinghyrax.deviantart.com/art/Rainmeter-Sudoku-Solver-419344963)

This is a Rainmeter skin that will solve Sudoku puzzles.  It uses my Lua implementation of Peter Norvig's [Python Sudoku solver.](http://norvig.com/sudoku.html)  It doesn't have much of a practical purpose - if you actually like Sudoku, then you'll solve puzzles by hand; and if you're actually trying to crack Sudokus algorithmically, then you'll probably write your own solver (and Rainmeter is not the best medium).  I just wrote it as a personal exercise.  It should solve any valid Sudoku grid - though if you don't give it enough constraints (clues) then it will only provide one of multiple possible solutions.

The coolest script feature is a "bullet time" mode - when it's on, the Lua script will update the skin every time the algorithm assigns a value to a cell, so you can watch the program solve the puzzle in slow motion.  For example, [here's a .gif](http://i.imgur.com/cQxJ4r1.gif) showing the skin solving [Arto Inkala's 2010 puzzle](http://www.dailymail.co.uk/news/article-1304222/It-took-months-create-long-crack--worlds-hardest-Sudoku.html).  It can be turned on and off by using the skin's context menu.

*How to use:*

- Left-click a cell to show a digit chooser for that cell
- Right-click the chooser to dismiss it
- Right-click a filled cell to clear it
- Scroll up/down on a cell to increment/decrement its value

Once you've entered your clues, just hit "solve."  "Clear grid" does exactly what it says on the tin.  In the context menu, you can toggle the slow motion effect and switch the skin between light and dark versions.  (Note that both context menu actions require the skin to refresh, so if you first fill in the grid, then use the context menu, the grid will be cleared.)

Requires the 3.0.2 release version of [Rainmeter](http://rainmeter.net/)