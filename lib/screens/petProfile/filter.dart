import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:flutter/material.dart';

class FilterPets extends StatefulWidget {
  const FilterPets({super.key});

  @override
  State<FilterPets> createState() => _FilterState();
}

class _FilterState extends State<FilterPets> {
  late Map<String, bool> filters;
  late Map<String, bool> tempFilters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    filters = Map<String, bool>.from(
        ModalRoute.of(context)?.settings.arguments as Map<String, bool>);
    tempFilters = Map<String, bool>.from(filters);
  }

  void updateAgeFilters() {
    if (tempFilters['babySelected']! &&
        tempFilters['youngSelected']! &&
        tempFilters['oldSelected']!) {
      setState(() {
        tempFilters['babySelected'] = false;
        tempFilters['youngSelected'] = false;
        tempFilters['oldSelected'] = false;
        tempFilters['anyAgeSelected'] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Filter Pet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // No data is passed back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              buildFilterSection('Type', [
                buildFilterOption('Dog', tempFilters['dogSelected']!, (value) {
                  setState(() {
                    tempFilters['dogSelected'] = value;
                  });
                }),
                buildFilterOption('Cats', tempFilters['catSelected']!, (value) {
                  setState(() {
                    tempFilters['catSelected'] = value;
                  });
                }),
                buildFilterOption(
                    'Other animals', tempFilters['otherSelected']!, (value) {
                  setState(() {
                    tempFilters['otherSelected'] = value;
                  });
                }),
              ]),
              buildFilterSection('Age', [
                buildFilterOption('Baby (<= 1)', tempFilters['babySelected']!,
                    (value) {
                  setState(() {
                    tempFilters['babySelected'] = value;
                    if (value) {
                      tempFilters['anyAgeSelected'] = false;
                    }
                    updateAgeFilters();
                  });
                }),
                buildFilterOption(
                    'Young (2 - 5)', tempFilters['youngSelected']!, (value) {
                  setState(() {
                    tempFilters['youngSelected'] = value;
                    if (value) {
                      tempFilters['anyAgeSelected'] = false;
                    }
                    updateAgeFilters();
                  });
                }),
                buildFilterOption('Old (> 6)', tempFilters['oldSelected']!,
                    (value) {
                  setState(() {
                    tempFilters['oldSelected'] = value;
                    if (value) {
                      tempFilters['anyAgeSelected'] = false;
                    }
                    updateAgeFilters();
                  });
                }),
                buildFilterOption('Any age', tempFilters['anyAgeSelected']!,
                    (value) {
                  setState(() {
                    tempFilters['anyAgeSelected'] = value;
                    if (value) {
                      tempFilters['babySelected'] = false;
                      tempFilters['youngSelected'] = false;
                      tempFilters['oldSelected'] = false;
                    }
                  });
                }),
              ]),
              buildFilterSection('Care Level', [
                buildFilterOption(
                    '1 - Basic Care', tempFilters['basicCareSelected']!,
                    (value) {
                  setState(() {
                    tempFilters['basicCareSelected'] = value;
                  });
                }),
                buildFilterOption(
                    '2 - Standard Care', tempFilters['standardCareSelected']!,
                    (value) {
                  setState(() {
                    tempFilters['standardCareSelected'] = value;
                  });
                }),
                buildFilterOption(
                    '3 - Moderate Care', tempFilters['moderateCareSelected']!,
                    (value) {
                  setState(() {
                    tempFilters['moderateCareSelected'] = value;
                  });
                }),
                buildFilterOption(
                    '4 - Advanced Care', tempFilters['advancedCareSelected']!,
                    (value) {
                  setState(() {
                    tempFilters['advancedCareSelected'] = value;
                  });
                }),
                buildFilterOption('5 - Specialized Care',
                    tempFilters['specializedCareSelected']!, (value) {
                  setState(() {
                    tempFilters['specializedCareSelected'] = value;
                  });
                }),
              ]),
              Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.01, 0, screenHeight * 0.0225),
                  child: createButton(screenWidth * 0.8, screenHeight * 0.06,
                      () {
                    Navigator.pop(context, tempFilters);
                  },
                      'Apply',
                      Colors.white,
                      screenHeight * 0.0225,
                      const Color.fromARGB(255, 247, 184, 1),
                      const Color.fromARGB(255, 241, 132, 1),
                      Colors.transparent,
                      Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFilterSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Column(children: options),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildFilterOption(
      String label, bool isSelected, Function(bool) onChanged) {
    return Row(
      children: [
        Switch(
          value: isSelected,
          onChanged: onChanged,
          activeColor: Colors.orange,
        ),
        Text(label),
      ],
    );
  }
}
