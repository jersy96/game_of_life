import 'dart:io';
import 'dart:math';

// Programe el juego de la vida

void main() {
  Console console = new Console();
  int size = console.readInt('Digite el tamaño de la matriz');
  GameOfLife game = new GameOfLife(size: size);
  console.setGame(game);
  console.startGame();
}

class Console {
  GameOfLife? game;

  String readString(message) {
    print(message);
    return stdin.readLineSync().toString();
  }

  int readInt(message) {
    return int.parse( readString(message) );
  }

  void drawMatrix() {
    for(var row in this.game!.matrix) {
      print(row.join(' '));
    }
    // this.readString('');
  }

  void setGame(GameOfLife game) {
    this.game = game;
  }

  void startGame() {
    this.drawMatrix();
    while (true) {
      this.game!.update();
      this.clearConsole();
      this.drawMatrix();
      sleep(const Duration(milliseconds: 500));
    }
  }

  void clearConsole() {
    print("\x1B[2J\x1B[0;0H");
  }
}

class GameOfLife {
  int size;
  late List<List<int>> matrix;

  GameOfLife({ required this.size }) {
    this.matrix = this.initMatrix();
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
    return matrix;
  }

  int getRandomValue() {
    return Random().nextInt(2);
  }

  void update() {
    List<List<int>> newMatrix = [];
    for(int i=0; i<this.size; i++) {
      List<int> row = [];
      for(int j=0; j<this.size; j++) {
        row.add( this.updateCell(i,j) );
      }
      newMatrix.add(row);
    }
    this.matrix = newMatrix;
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
}