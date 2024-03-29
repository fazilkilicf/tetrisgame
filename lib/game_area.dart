import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tetris/constants/path_constants.dart';
import 'package:tetris/constants/size_constants.dart';
import 'package:tetris/constants/text_constants.dart';
import 'package:tetris/piece.dart';
import 'package:tetris/pixel.dart';
import 'package:tetris/values.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'utils/style_utils.dart';

/*

GAME AREA 

This is a 2x2 grid with null representing an empty space.
A non empty space will have the color to represent the landed pieces

*/

// create game area
List<List<Tetromino?>> gameArea =
    List.generate(colLength, (i) => List.generate(rowLength, (index) => null));

class GameArea extends StatefulWidget {
  const GameArea({super.key});

  @override
  State<GameArea> createState() => _GameAreaState();
}

class _GameAreaState extends State<GameArea> {
  // current tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);

  // frame refresh rate
  Duration frameRate = const Duration(milliseconds: 500);

  // current score
  int currentScore = 0;

  // game over status
  bool gameOver = false;

  // pause game
  bool pause = false;

  @override
  void initState() {
    super.initState();

    // start game when app starts
    /* startGame(); */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGameDialog();
    });
  }

  void startGame() {
    currentPiece.initializePiece();

    gameLoop(frameRate);
  }

  // game loop
  void gameLoop(Duration frameRate) {
    Timer.periodic(
      frameRate,
      (timer) {
        setState(() {
          // clear lines
          clearLines();

          // check if game is over
          if (gameOver == true) {
            timer.cancel();
            showGameOverDialog();
          }

          // check if game is paused
          if (pause == true) {
            timer.cancel();
            showPauseDialog();
          }

          // check landing
          checkLanding();

          currentPiece.movePiece(Direction.down);
        });
      },
    );
  }

  // pause game
  void pauseGame() {
    setState(() {
      pause = true;
    });
  }

  // resume game
  void resumeGame() {
    Navigator.pop(context);
    setState(() {
      pause = false;
    });
    gameLoop(frameRate);
  }

  // restart game
  void restartGame() {
    setState(() {
      pause = false;
    });
    resetGame();
  }

  // game dialog
  void showGameDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog.fullscreen(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    PathConstants.tetrisImgPath,
                    width: 128.0,
                    height: 128.0,
                  ),
                  SizedBox(height: defaultVerticalPadding(context)),
                  const Text(
                    TextConstants.appName,
                    style: tetrisHeadStyle,
                  ),
                  TextButton(
                      onPressed: () {
                        // close dialog
                        Navigator.pop(context);

                        // reset game
                        resetGame();
                      },
                      child: const Text(TextConstants.startGameText,
                          style: appMenuElementStyle)),
                  SizedBox(height: defaultVerticalPadding(context)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('developed by efka', style: developedByStyle),
                      AnimatedEmoji(
                        AnimatedEmojis.sunglassesFace,
                        size: 34,
                        repeat: true,
                      ),
                    ],
                  ),
                ],
              ),
            ));
  }

  // game paused dialog
  void showPauseDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog.fullscreen(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    TextConstants.pausedText,
                    style: tetrisHeadStyle,
                  ),
                  SizedBox(height: defaultVerticalPadding(context) * 1 / 2),
                  TextButton(
                      onPressed: resumeGame,
                      child: const Text(TextConstants.resumeText,
                          style: appMenuElementStyle)),
                  SizedBox(height: defaultVerticalPadding(context) * 1 / 2),
                  TextButton(
                      onPressed: () {
                        // close dialog
                        Navigator.pop(context);

                        // restart game
                        restartGame();
                      },
                      child: const Text(TextConstants.restartText,
                          style: appMenuElementStyle)),
                  SizedBox(height: defaultVerticalPadding(context) * 1 / 2),
                  TextButton(
                      onPressed: () {
                        // close dialog
                        Navigator.pop(context);

                        // show main game dialog
                        showGameDialog();
                      },
                      child: const Text(TextConstants.mainMenuText,
                          style: appMenuElementStyle)),
                ],
              ),
            ));
  }

  // game over message
  void showGameOverDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog.fullscreen(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    TextConstants.gameOverText,
                    style: tetrisHeadStyle,
                  ),
                  Text(
                    'Score: $currentScore',
                    style: gameScoreStyle,
                  ),
                  SizedBox(height: defaultVerticalPadding(context) * 1 / 2),
                  TextButton(
                      onPressed: () {
                        // close dialog
                        Navigator.pop(context);

                        // reset game
                        resetGame();
                      },
                      child: const Text(TextConstants.playAgainText,
                          style: appMenuElementStyle)),
                  SizedBox(height: defaultVerticalPadding(context) * 1 / 2),
                  TextButton(
                      onPressed: () {
                        // close dialog
                        Navigator.pop(context);

                        // show main game dialog
                        showGameDialog();
                      },
                      child: const Text(TextConstants.mainMenuText,
                          style: appMenuElementStyle)),
                ],
              ),
            ));
  }

  // reset game
  void resetGame() {
    // clear the game area
    gameArea = List.generate(
      colLength,
      (index) => List.generate(rowLength, (j) => null),
    );

    // new game
    gameOver = false;
    currentScore = 0;

    // create new piece
    createNewPiece();

    // start game again
    startGame();
  }

  // check for collision in a future position
  // return true -> there is a collision
  // return false -> there is a no collision
  bool checkCollision(Direction direction) {
    // loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      // calculate the row and column of the current positions
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // adjust the row and col based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else {
        row += 1;
      }

      // check if the piece out of bounds (either to low or too far to the left or right)
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }

      // check if the current position is already occupied by another piece in the game area
      if (row >= 0 && col >= 0) {
        if (gameArea[row][col] != null) {
          return true;
        }
      }
    }
    // if no collisions are detected, return false
    return false;
  }

  void checkLanding() {
    // if going down is occupied
    if (checkCollision(Direction.down)) {
      // mark position as occupied on the gamearea
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameArea[row][col] = currentPiece.type;
        }
      }
      // once landed, create the next piece
      createNewPiece();
    }
  }

  void createNewPiece() {
    // create a random object to  generate random tetromino types
    Random rnd = Random();

    // create a new piece with random type
    Tetromino randomType =
        Tetromino.values[rnd.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    /*
      
      Since our game over condition is if there is a piece at the top level,
      you want to check if the game is over when you create a new piece,
      instead of checking every frame, because new pieces are allowed to go through the top level
      but if there is already a piece in the top level when the new piece is created,
      then game is over

    */

    if (isGameOver()) {
      setState(() {
        gameOver = true;
      });
    }
  }

  // move left
  void moveLeft() {
    // make sure the move is valid before moving there
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  // move right
  void moveRight() {
    // make sure the move is valid before moving there
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  // rotate piece
  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  // clear lines
  void clearLines() {
    // step 1: Loop through each row of the game area from bottom to top
    for (int row = colLength - 1; row >= 0; row--) {
      // step 2: Initialize a variable to track if the row is full
      bool rowIsFull = true;

      // step 3: Check if the row if full (all columns in the row are filled with pieces)
      for (int col = 0; col < rowLength; col++) {
        // if there's an empty column, set rowIsFull to false and break to loop
        if (gameArea[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      // step 4: if the row is full, clear the row and shift rows down
      if (rowIsFull) {
        // step 5: move all  rows above  the cleared row down by one position
        for (int r = row; r > 0; r--) {
          // copy the above row to the current row
          gameArea[r] = List.from(gameArea[r - 1]);
        }

        // step 6: set the top row to empty
        gameArea[0] = List.generate(row, (index) => null);

        // step 7: Increase the score!
        currentScore++;
      }
    }
  }

  // GAME OVER METHOD
  bool isGameOver() {
    // check if any columns in the top row are filled
    for (int col = 0; col < rowLength; col++) {
      if (gameArea[0][col] != null) {
        return true;
      }
    }

    // if the top row is empty, the game is not over
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // GAME GRID
          Expanded(
            child: GridView.builder(
                itemCount: rowLength * colLength,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowLength),
                itemBuilder: (context, index) {
                  // get row and col of each index
                  int row = (index / rowLength).floor();
                  int col = index % rowLength;

                  // current piece
                  if (currentPiece.position.contains(index)) {
                    return Pixel(color: currentPiece.color);
                  }

                  // landed pieces
                  else if (gameArea[row][col] != null) {
                    final Tetromino? tetrominoType = gameArea[row][col];
                    return Pixel(color: tetrominoColors[tetrominoType]);
                  }
                  // blank pixel
                  else {
                    return Pixel(color: Colors.grey[900]);
                  }
                }),
          ),

          // Menu Text Button
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextButton(
                onPressed: pauseGame,
                child: const Text(TextConstants.menuText,
                    style: appMenuElementStyle)),
          ),

          // SCORE
          Text(
            'Score: $currentScore',
            style: gameScoreStyle,
          ),

          // GAME CONTROLS
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // left
                IconButton(
                    onPressed: moveLeft,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_ios)),

                // rotate
                IconButton(
                    onPressed: rotatePiece,
                    color: Colors.white,
                    icon: const Icon(Icons.rotate_right)),

                // right
                IconButton(
                    onPressed: moveRight,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_forward_ios)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
