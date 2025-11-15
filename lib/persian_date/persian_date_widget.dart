import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/persian_date/persian_date.dart';
import 'package:date_picker_timeline/persian_date/persian_number.dart';
import 'package:flutter/material.dart';

class PersianDateWidget extends StatelessWidget {
  final double? width;
  final DateTime date;
  final TextStyle? monthTextStyle, dayTextStyle, dateTextStyle;
  final Color selectionColor;
  final DateSelectionCallback? onDateSelected;
  final String? locale;

  PersianDateWidget({
    required this.date,
    required this.monthTextStyle,
    required this.dayTextStyle,
    required this.dateTextStyle,
    required this.selectionColor,
    this.width,
    this.onDateSelected,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))
      ),
      child: Container(
        width: width,
        margin: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          color: selectionColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text((PersianDate.persianMonthNames(date.month)), // Month
                  style: monthTextStyle,
                  overflow: TextOverflow.visible,
                  maxLines: 1),
              Text('${date.day}'.toPersianDigit(), // Date
                  style: dateTextStyle,
                  overflow: TextOverflow.visible,
                  maxLines: 1),
              Text((PersianDate.persianWeeklyName(date)), // WeekDay
                  style: dayTextStyle,
                  overflow: TextOverflow.visible,
                  maxLines: 1)
            ],
          ),
        ),
      ),
      onTap: () {
        onDateSelected?.call(this.date);
      },
    );
  }
}