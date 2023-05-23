import 'dart:developer';
import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';

// Programe el juego de la vida!

void main() {
  Console console = new Console();
  GameOfLife game = new GameOfLife();
  
  console.setGame(game);
  console.setGameSize('Digite el tamaño de la matriz: ');
  console.setGameColor('Ingrese el color del juego r (Red), g (Green), y (Yellow), b (Blue), m (Magenta), c (Cyan), w (White), d (Default): ');
  
  console.startGame();
}

class Console {
  GameOfLife? game;
  Map COLORS = {
      'r': '\x1B[31m',
      'g': '\x1B[32m',
      'y': '\x1B[33m',
      'b': '\x1B[34m',
      'm': '\x1B[35m',
      'c': '\x1B[36m',
      'w': '\x1B[37m',
      'd': '\x1B[0m',
      'black': '\x1B[30m',
      'random': true,
      'rainbow': true,
    };
  static const String defaultPromptColor = '\x1B[33m';

  String readString(message, [color = defaultPromptColor]) {
    print(color + message + color);
    return stdin.readLineSync().toString().toLowerCase();
  }

  String readOption(message, options, [color = defaultPromptColor]) {
    String attemptKey = readString(message, color);
    bool repeat = !options.containsKey(attemptKey);
    String errorColor = getColor('r');
    while (repeat) {
      print(errorColor + ' Error - invalid option ' + attemptKey + '!' + errorColor);
      attemptKey = readString(message, color);
      repeat = !options.containsKey(attemptKey);
    }
    return attemptKey;
  }

  String getOption(option, options) {
    var res = options[option];
    if (option == 'random') {
      res = options.values.elementAt(new Random().nextInt(options.length)); 
      while (res == true) {
        res = options.values.elementAt(new Random().nextInt(options.length)); 
      }
    }
    return res;
  }

  int readInt(message, [color = defaultPromptColor]) {
    String errorColor = getColor('r');
    while (true) {
      try {
        return int.parse(readString(message, color));
      } catch (e) {
        print(errorColor + ' Error - invalid number!' + errorColor);
      }
    }
  }

  void setGame(GameOfLife game) {
    this.game = game;
  }

  void setGameSize(message) {
    int size = readInt(message);
    String errorColor = getColor('r');
    while (size <= 0) {
      print(errorColor + ' Error - invalid size!' + errorColor);
      size = readInt(message);
    }
    game?.size = size;
  }

  void setGameColor(message) {
    String color = readOption(message, COLORS);
    if (color == 'rainbow') {
      game?.color = 'rainbow';
    } else {
      game?.color = getColor(color);
    }
  }

  void startGame() {
    this.game!.init();

    bool playing = true;
    while (playing) {
      this.game!.thick();
      this.render();
      sleep(const Duration(milliseconds: 500));

      playing = this.game!.running;
    }
  }

  void render() {
    this.clearConsole();
    this.drawMatrix();
  }

  void clearConsole() {
    print("\x1B[2J\x1B[0;0H");
  }

  void drawMatrix() {
    for(var line in this.game!.matrix) {
      String row = '';
      for(int element in line) {
        String color = (element > 0) ? getColor() : getColor('w');
        row += (color + element.toString() + color);
      }
      print(row);
    }
  }

  String getColor([color = '']) {
    if (color != '') {
      return getOption(color, COLORS); 
    } else if (game?.color == 'rainbow') {
      return getOption('random', COLORS);
    } else if (game?.color != '') {
      return game?.color ?? 'yellow';
    } else {
      return getOption('yellow', COLORS);
    }
  }
}

class GameOfLife {
  int size = 0;
  late List<List<int>> matrix;
  late List<List<int>> lastFrame;
  late List<List<int>> penultimateFrame;
  String color = '';
  bool running = false;

  GameOfLife() {}

  void init() {
    this.matrix = this.initMatrix();
  }

  void thick() {
    this.running = update();
  }

  List<List<int>> initMatrix() {
    List<List<int>> matrix = [];
    for(int i=0; i<this.size; i++) {
      List<int> row = [];
      for(int j=0; j<this.size; j++) {
        row.add( this.getRandomValue() );
      }
      matrix.add(row);
    }
    lastFrame = List.generate(size, (index) => List<int>.filled(size, 0));
    penultimateFrame = List.generate(size, (index) => List<int>.filled(size, 0));

    return matrix;
  }

  int getRandomValue() {
    return Random().nextInt(2);
  }

  bool update() {
    if (size < 0) {
      return false;
    }

    bool cellUpdated = false;
    List<List<int>> newMatrix = [];
    for(int i=0; i<this.size; i++) {
      List<int> row = [];
      for(int j=0; j<this.size; j++) {
        row.add( this.updateCell(i,j) );
      }
      if (!cellUpdated) {
        cellUpdated = !ListEquality().equals(row, matrix[i]);
      }
      newMatrix.add(row);
    }

    bool stuck = gameStuck(newMatrix);
    this.matrix = newMatrix;

    return cellUpdated || stuck;
  }

  bool gameStuck(newMatrix) {
    bool stuck = false;
    if (!isAllZeros(penultimateFrame) && !isAllZeros(lastFrame)) {
      // todo: Stop the Game in patterns bigger than 2 frame repetition. The largest frame repetition I have seen was of 4.
      stuck = DeepCollectionEquality().equals(newMatrix, lastFrame) && DeepCollectionEquality().equals(matrix, penultimateFrame);
    } else if (!isAllZeros(lastFrame)) {
      this.penultimateFrame = this.lastFrame;
    }
    this.lastFrame = this.matrix;

    return stuck;
  }

  int updateCell(int i, int j) {
    int aliveNextCells = this.getAliveNextCells(i,j);
    bool isCellAlive = this.matrix[i][j] == 1;
    if (isCellAlive) {
      return aliveNextCells == 2 || aliveNextCells == 3 ? 1 : 0;
    } else {
      return aliveNextCells == 3 ? 1 : 0;
    }
  }

  int getAliveNextCells(int i, int j) {
    List<List<int>> nextCellsCoords = [
      [i-1,j],
      [i-1,j+1],
      [i,j+1],
      [i+1,j+1],
      [i+1,j],
      [i+1,j-1],
      [i,j-1],
      [i-1,j-1],
    ];
    int aliveNextCells = 0;
    for (List coord in nextCellsCoords) {
      if (this.coordInmatrix(coord)) {
        aliveNextCells += this.matrix[ coord[0] ][ coord[1] ];
      }
    }
    return aliveNextCells;
  }

  bool coordInmatrix(List coord) {
    return coord[0] >= 0 && coord[0] < this.size && coord[1] >= 0 && coord[1] < this.size;
  }

  bool isAllZeros(List<List<int>> matrix) {
    return !matrix.any((row) => row.contains(1));
  }
}