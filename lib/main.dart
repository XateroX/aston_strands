import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

final Random _random = Random();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aston Strands',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StrandsWidget(title:"Aston Strands"),
    );
  }
}

class StrandsWidget extends StatefulWidget {
  const StrandsWidget({super.key, required this.title});

  final String title;

  @override
  State<StrandsWidget> createState() => _StrandsWidgetState();
}

class _StrandsWidgetState extends State<StrandsWidget> {
  bool _showAllWords = false;
  bool _showWordBank = true;
  bool _needToRegenerateBoard = false;

  List<Tuple2<int,int>> selectedLocations = [];

  List<String> foundWords = [];

  Tuple2<int,int> gridDims = Tuple2(6,8);

  List<String> wordsList = [
    "Piece",
    "Peace",
    "Straight",
    "Egypt",
    "Biscuit",
    "Cook",
    "Circus",
  ];

  Map<String,Color> wordColors = {};

  Map<String,List<Tuple2<int,int>>> wordLocationData = {};

  List<String> letterGridContents = [];

  void evaluatePressedLetters(Tuple2<int,int> tapLocation){
    final tappedWord = getContainingWord(tapLocation);
    if (tappedWord != null) {
      print("Tapped word: $tappedWord");
    }
    
    if (
      selectedLocations.any((location) => location.item1 == tapLocation.item1 && location.item2 == tapLocation.item2) && 
      selectedLocations.indexOf(tapLocation)==(selectedLocations.length-1)
    ) {
      setState(() {
        selectedLocations.remove(tapLocation);
      });
    } else if (
      selectedLocations.isEmpty || (
        !selectedLocations.any((location) => location.item1 == tapLocation.item1 && location.item2 == tapLocation.item2) &&
        (tapLocation.item1 - selectedLocations.last.item1).abs() <= 1 &&
        (tapLocation.item2 - selectedLocations.last.item2).abs() <= 1
      )
    ){
      setState(() {
        selectedLocations.add(tapLocation);
      });
      if (
        (
          wordLocationData[tappedWord]!.every(
            (wordLocation) => selectedLocations.any(
              (selectedLocation) => wordLocation.item1 == selectedLocation.item1 && wordLocation.item2 == selectedLocation.item2
            )
          ) && selectedLocations.every(
            (selectedLocation) => wordLocationData[tappedWord]!.any(
              (wordLocation) => wordLocation.item1 == selectedLocation.item1 && wordLocation.item2 == selectedLocation.item2
            )
          )
        ) || tappedWord!.characters.every(
          (character) => selectedLocations.any(
            (selectedLocation) => letterGridContents[selectedLocation.item1+selectedLocation.item2*gridDims.item1].toUpperCase() == character.toUpperCase()
          )
        )
      ){
        setState(() {
          foundWords.add(tappedWord!);
        });
        selectedLocations = [];
      }
    }
  }

  String? getContainingWord(Tuple2<int,int> target){
    for (List<Tuple2<int,int>> wordLocationList in wordLocationData.values){
      for (Tuple2<int,int> letterLocation in wordLocationList){
        if (
          target.item1 == letterLocation.item1 && 
          target.item2 == letterLocation.item2 
        ){
          return wordLocationData.keys.toList()[wordLocationData.values.toList().indexOf(wordLocationList)];
        }
      }
    }
    return null;
  }

  bool locationInExistingWord(Tuple2<int,int> target){
    for (List<Tuple2<int,int>> wordLocationList in wordLocationData.values){
      for (Tuple2<int,int> letterLocation in wordLocationList){
        if (
          target.item1 == letterLocation.item1 && 
          target.item2 == letterLocation.item2 
        ){
          return true;
        }
      }
    }
    return false;
  }

  String generateRandomLetter(){
    final int charCodeUnitMin = 65;
    final int charCodeUnitMax = 90;
    return String.fromCharCode(_random.nextInt(charCodeUnitMax - charCodeUnitMin + 1) + charCodeUnitMin);
  }

  bool gridContainsAtLeastOneFreeSpace(){
    return true;
  }

  bool gridLocationAvailable(Tuple2<int,int> target){
    return true;
  }

  bool gridLocationContainsMe(String myWord){
    return false;
  }

  bool gridLocationValid(Tuple2<int,int> target){
    return 
      target.item1 < gridDims.item1 && 
      target.item2 < gridDims.item2 &&
      target.item1 >= 0 && 
      target.item2 >= 0;
  }

  @override
  void initState() {
    super.initState();
    setupNewBoard();
  }

  void setupNewBoard(){
    Color randomNiceColor() {
      final rnd = Random();

      // Hue: anywhere on the color wheel (0–360)
      final hue = rnd.nextDouble() * 360;

      // Saturation: keep it fairly high (e.g., 0.7–1.0)
      final saturation = 0.7 + rnd.nextDouble() * 0.3;

      // Lightness: avoid extremes (e.g., 0.4–0.6 for nice vivid colors)
      final lightness = 0.45 + rnd.nextDouble() * 0.2;

      return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    }

    // generate word colors
    for (String word in wordsList){
      wordColors[word] = randomNiceColor();
    }

    // initialise random grid
    for (int i = 0; i < gridDims.item1*gridDims.item2; i++){
      int xInd = i % gridDims.item1;
      int yInd = (i / gridDims.item1).floor();
      letterGridContents.add(generateRandomLetter());
    }

    int totalWordLength = 0;
    for (String word in wordsList){
      totalWordLength += word.length;
    }
    if (totalWordLength < gridDims.item1*gridDims.item2 - 4){
      // inject our words into it
      bool generatingWholeGrid = true;
      while(generatingWholeGrid){
        generatingWholeGrid = false;
        for (String word in wordsList){
          bool placingWord = true;
          int wordAttempts = 0;
          while(placingWord){
            if (wordAttempts > 10){
              generatingWholeGrid = true;
              break;
            }

            placingWord = false;
            wordLocationData[word] = [];

            Tuple2<int,int> wordInitialLocation = Tuple2(
              _random.nextInt(gridDims.item1),
              _random.nextInt(gridDims.item2)
            );

            while(
              locationInExistingWord(wordInitialLocation) && 
              gridContainsAtLeastOneFreeSpace()
            ){
              wordInitialLocation = Tuple2(
                _random.nextInt(gridDims.item1),
                _random.nextInt(gridDims.item2)
              );
            }

            Tuple2<int,int> currentLetterLocation = Tuple2<int,int>(
              wordInitialLocation.item1,
              wordInitialLocation.item2,
            );
          
            for (String letter in word.characters){
              print(letter);

              Tuple2<int,int> nextMove = Tuple2(
                _random.nextInt(3)-1,
                _random.nextInt(3)-1,
              );

              Tuple2<int,int> targetLocation = Tuple2<int,int>(
                currentLetterLocation.item1 + nextMove.item1,
                currentLetterLocation.item2 + nextMove.item2,
              );

              int attempt = 0;

              while(
                (
                  (
                    locationInExistingWord(targetLocation) ||
                    !gridLocationValid(targetLocation)
                  ) && 
                  gridContainsAtLeastOneFreeSpace()
                ) && attempt < 100
              ){
                nextMove = Tuple2(
                  _random.nextInt(3)-1,
                  _random.nextInt(3)-1,
                );
                targetLocation = Tuple2<int,int>(
                  currentLetterLocation.item1 + nextMove.item1,
                  currentLetterLocation.item2 + nextMove.item2,
                );

                attempt++;
                print("$word $letter Attempt:$attempt");
                print("Target:$targetLocation");
              }

              if (attempt >= 100){
                placingWord = true;
                wordAttempts++;
                print("$word Attempted $wordAttempts times");
                break;
              }

              wordLocationData[word]!.add(targetLocation);
              letterGridContents[targetLocation.item2*gridDims.item1 + targetLocation.item1] = letter.toUpperCase();
              currentLetterLocation = Tuple2<int,int>(targetLocation.item1,targetLocation.item2);
            }
          }
        }
      }
      print("");
    } else  {
      print("Grid too small to fit words");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _showWordBank = false;
                setupNewBoard();
                _needToRegenerateBoard = false;
              });
            },
          ),
          IconButton(
            icon: Icon(_showAllWords ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showAllWords = !_showAllWords;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.list_sharp),
            onPressed: () {
              setState(() {
                _showWordBank = !_showWordBank;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _showWordBank ? Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 230, 230, 230),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          maxLines: 1,
                          style: TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your words here',
                            filled: true,
                            fillColor: Colors.white
                          ),
                          onSubmitted: (String value) {
                            setState(() {
                              int totalWordLength = value.length;
                              for (String word in wordsList){
                                totalWordLength += word.length;
                              }
                              if (totalWordLength < gridDims.item1*gridDims.item2 - 4){
                                wordsList.add(value);
                                _needToRegenerateBoard = true;
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Grid too small to fit \"$value\"",
                                      style: TextStyle(
                                        fontSize: 36
                                      ),
                                    ),
                                    backgroundColor: Color.fromARGB(200, 200, 0, 0),
                                  )
                                );
                              }
                            });
                          },
                        ),
                        ...wordsList.map((word) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(word, style: TextStyle(fontSize: 24),),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      wordsList.remove(word);
                                      _needToRegenerateBoard = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ): Text(
              "Found ${foundWords.length}/${wordsList.length} words",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        selectedLocations.map((location)=>letterGridContents[location.item2*gridDims.item1 + location.item1]).join(""),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    secondChild: Container(),
                    crossFadeState: selectedLocations.isNotEmpty ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 500),
                  ),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 230, 230, 230)
                        ),
                        child: 
                        !_needToRegenerateBoard ? ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxHeight*(gridDims.item1/gridDims.item2),
                            maxHeight: constraints.maxWidth*(gridDims.item2/gridDims.item1),
                            minWidth: constraints.maxHeight*(gridDims.item1/gridDims.item2),
                            minHeight: constraints.maxWidth*(gridDims.item2/gridDims.item1)
                          ),
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: ConnectionPainter(
                                  gridDims: gridDims,
                                  selectedLocations: selectedLocations,
                                  wordColors: wordColors,
                                  getContainingWord: getContainingWord,
                                  wordsList: wordsList,
                                  foundWords: foundWords,
                                  wordLocationData: wordLocationData,
                                  showAllWords:_showAllWords,
                                ),
                                child: Container(),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  gridDims.item2, 
                                  (int rowIndex) { 
                                    return Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: List.generate(
                                          gridDims.item1, 
                                          (int colIndex) { 
                                            String? myWord = getContainingWord(Tuple2<int,int>(colIndex,rowIndex));
                                        
                                            return Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    final tapLocation = Tuple2<int,int>(colIndex,rowIndex);
                                                    evaluatePressedLetters(tapLocation);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: foundWords.contains(myWord) || _showAllWords
                                                        ? wordColors[getContainingWord(Tuple2<int,int>(colIndex,rowIndex))] 
                                                        : selectedLocations.any((location)=>location.item1 == colIndex && location.item2 == rowIndex)
                                                          ? Color.fromARGB(255, 100, 100, 100)
                                                          : Color.fromARGB(255, 255, 255, 255),
                                                      shape: BoxShape.circle
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        letterGridContents[rowIndex*gridDims.item1 + colIndex],
                                                        style: TextStyle(
                                                          fontSize: max(constraints.maxHeight*0.05, 16) // rough scaling to be sensible
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ); 
                                          }
                                        )
                                      ),
                                    );
                                  }
                                ) ,
                              ),
                            ]
                          ),
                        ): Container(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Press the regenerate button to \n generate a new board",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ]
        ),
      ),
    );
  }
}



class ConnectionPainter extends CustomPainter {
  final Tuple2<int,int> gridDims;
  final List<Tuple2<int,int>> selectedLocations;
  final Map<String,Color> wordColors;
  String? Function(Tuple2<int,int>) getContainingWord;
  final List<String> foundWords;
  final List<String> wordsList;
  final Map<String,List<Tuple2<int,int>>> wordLocationData;
  final bool showAllWords;

  ConnectionPainter({
    required this.gridDims,
    required this.selectedLocations,
    required this.wordColors,
    required this.getContainingWord,
    required this.wordsList,
    required this.foundWords,
    required this.wordLocationData,
    required this.showAllWords,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < selectedLocations.length-1; i++) {
      Tuple2<int,int> loc1 = selectedLocations[i];
      Tuple2<int,int> loc2 = selectedLocations[i+1];

      String? locWord = getContainingWord(loc1);

      final paint = Paint()
        ..color = (locWord!=null && foundWords.contains(locWord)) ? wordColors[locWord]! : Colors.grey
        ..strokeWidth = 10.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(
          (loc1.item1+0.5)*size.width/gridDims.item1, 
          (loc1.item2+0.5)*size.height/gridDims.item2
        ), 
        Offset(
          (loc2.item1+0.5)*size.width/gridDims.item1, 
          (loc2.item2+0.5)*size.height/gridDims.item2
        ),
        paint
      );
    }

    for (String currentWord in (showAllWords ?  wordsList : foundWords)) {
      List<Tuple2<int,int>> wordLocations = wordLocationData[currentWord]!;
      for (int i = 0; i < wordLocations.length-1; i++) {
        Tuple2<int,int> loc1 = wordLocations[i];
        Tuple2<int,int> loc2 = wordLocations[i+1];

        String? locWord = getContainingWord(loc1);

        final paint = Paint()
          ..color = (locWord!=null && (showAllWords ?  wordsList : foundWords).contains(locWord)) ? wordColors[locWord]! : Colors.grey
          ..strokeWidth = 10.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(
            (loc1.item1+0.5)*size.width/gridDims.item1, 
            (loc1.item2+0.5)*size.height/gridDims.item2
          ), 
          Offset(
            (loc2.item1+0.5)*size.width/gridDims.item1, 
            (loc2.item2+0.5)*size.height/gridDims.item2
          ),
          paint
        );
      }
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) => false;
}