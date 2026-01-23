import 'package:date_picker_timeline/gregorian_date/gregorian_date_widget.dart';
import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/extra/style.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/persian_date/persian_date.dart';
import 'package:date_picker_timeline/persian_date/persian_date_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

part 'date_type.dart';

class DatePicker extends StatefulWidget {
  /// Start Date in case user wants to show past dates
  /// If not provided calendar will start from the initialSelectedDate
  final DateTime startDate;

  /// Width of the selector
  final double width;

  /// Height of the selector
  final double height;

  /// DatePicker Controller
  final DatePickerController? controller;

  /// Text color for the selected Date
  final Color selectedTextColor;

  /// Background color for the selector
  final Color selectionColor;

  /// Text Color for the deactivated dates
  final Color deactivatedColor;

  /// TextStyle for Month Value
  final TextStyle monthTextStyle;

  /// TextStyle for day Value
  final TextStyle dayTextStyle;

  /// TextStyle for the date Value
  final TextStyle dateTextStyle;

  /// Current Selected Date
  final DateTime? /*?*/ initialSelectedDate;

  /// Contains the list of inactive dates.
  /// All the dates defined in this List will be deactivated
  final List<DateTime>? inactiveDates;

  /// Contains the list of active dates.
  /// Only the dates in this list will be activated.
  final List<DateTime>? activeDates;

  /// Callback function for when a different date is selected
  final DateChangeListener? onDateChange;

  /// Max limit up to which the dates are shown.
  /// Days are counted from the startDate
  final int daysCount;

  /// Calendar type
  final CalendarType calendarType;

  /// Directionality
  final TextDirection? directionality;

  /// Locale for the calendar default: en_us
  final String locale;

  /// Whether to center the selected date in the viewport
  final bool centerSelectedDate;

  DatePicker(
    this.startDate, {
    Key? key,
    this.width = 60,
    this.height = 80,
    this.controller,
    this.monthTextStyle = defaultMonthTextStyle,
    this.dayTextStyle = defaultDayTextStyle,
    this.dateTextStyle = defaultDateTextStyle,
    this.selectedTextColor = Colors.white,
    this.selectionColor = AppColors.defaultSelectionColor,
    this.deactivatedColor = AppColors.defaultDeactivatedColor,
    this.initialSelectedDate,
    this.activeDates,
    this.inactiveDates,
    this.daysCount = 500,
    this.onDateChange,
    this.locale = "en_US",
    this.calendarType = CalendarType.gregorianDate,
    this.directionality,
    this.centerSelectedDate = true,
  }) : assert(
            activeDates == null || inactiveDates == null,
            "Can't "
            "provide both activated and deactivated dates List at the same time.");

  @override
  State<StatefulWidget> createState() => new _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _currentDate;

  ScrollController _controller = ScrollController();

  late final TextStyle selectedDateStyle;
  late final TextStyle selectedMonthStyle;
  late final TextStyle selectedDayStyle;

  late final TextStyle deactivatedDateStyle;
  late final TextStyle deactivatedMonthStyle;
  late final TextStyle deactivatedDayStyle;

  @override
  void initState() {
    // Init the calendar locale
    initializeDateFormatting(widget.locale, null);

    // Set initial Values
    _currentDate = widget.initialSelectedDate;

    widget.controller?.setDatePickerState(this);

    this.selectedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.selectedTextColor);
    this.selectedMonthStyle =
        widget.monthTextStyle.copyWith(color: widget.selectedTextColor);
    this.selectedDayStyle =
        widget.dayTextStyle.copyWith(color: widget.selectedTextColor);

    this.deactivatedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.deactivatedColor);
    this.deactivatedMonthStyle =
        widget.monthTextStyle.copyWith(color: widget.deactivatedColor);
    this.deactivatedDayStyle =
        widget.dayTextStyle.copyWith(color: widget.deactivatedColor);

    // Center the initial selected date if centerSelectedDate is enabled
    if (widget.centerSelectedDate && _currentDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _jumpToCenter(_currentDate!);
        }
      });
    }

    super.initState();
  }

  /// Calculate the number of pixels that needs to be scrolled to go to the
  /// date provided in the argument
  double _calculateDateOffset(DateTime date) {
    final startDate = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );

    int offset = date.difference(startDate).inDays;
    // Each item width + margin on both sides (3px each = 6px total)
    double itemTotalWidth = widget.width + 6;
    return offset * itemTotalWidth;
  }

  /// Calculates the center offset for a given date
  double _calculateCenterOffset(DateTime date) {
    final dateOffset = _calculateDateOffset(date);
    final viewportWidth = _controller.position.viewportDimension;
    return (dateOffset - (viewportWidth / 2) + (widget.width / 2)).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
  }

  /// Jumps to center the selected date without animation
  void _jumpToCenter(DateTime selectedDate) {
    if (_controller.hasClients) {
      _controller.jumpTo(_calculateCenterOffset(selectedDate));
    }
  }

  /// Centers the selected date in the viewport with animation
  void _centerDate(DateTime selectedDate) {
    if (_controller.hasClients) {
      _controller.animateTo(
        _calculateCenterOffset(selectedDate),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Animates the scroll to center the selected date (scheduled for next frame)
  void _animateToCenter(DateTime selectedDate) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerDate(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: (widget.directionality) ??
          ((widget.calendarType == CalendarType.persianDate)
              ? TextDirection.rtl
              : TextDirection.ltr),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.1, 0.9, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Container(
          height: widget.height,
          child: ListView.builder(
            itemCount: widget.daysCount,
            scrollDirection: Axis.horizontal,
            controller: _controller,
            itemBuilder: (context, index) {
              // get the date object based on the index position
              // if widget.startDate is null then use the initialDateValue
              DateTime date;
              DateTime _date = widget.startDate.add(Duration(days: index));
              switch (widget.calendarType) {
                case CalendarType.persianDate:
                  date =
                      PersianDate.toJalali(_date.year, _date.month, _date.day);
                  break;
                case CalendarType.gregorianDate:
                  date = DateTime(_date.year, _date.month, _date.day);
                  break;
                default:
                  date = DateTime(_date.year, _date.month, _date.day);
              }
              bool isDeactivated = false;

              // check if this date needs to be deactivated for only DeactivatedDates
              if (widget.inactiveDates != null) {
                for (DateTime inactiveDate in widget.inactiveDates!) {
                  if (DateUtils.isSameDay(date, inactiveDate)) {
                    isDeactivated = true;
                    break;
                  }
                }
              }

              // check if this date needs to be deactivated for only ActivatedDates
              if (widget.activeDates != null) {
                isDeactivated = true;
                for (DateTime activateDate in widget.activeDates!) {
                  if (DateUtils.isSameDay(date, activateDate)) {
                    isDeactivated = false;
                    break;
                  }
                }
              }

              // Check if this date is the one that is currently selected
              bool isSelected = _currentDate != null
                  ? DateUtils.isSameDay(date, _currentDate!)
                  : false;
              // Return the Date Widget
              switch (widget.calendarType) {
                case CalendarType.gregorianDate:
                  return GregorianDateWidget(
                    date: date,
                    monthTextStyle: isDeactivated
                        ? deactivatedMonthStyle
                        : isSelected
                            ? selectedMonthStyle
                            : widget.monthTextStyle,
                    dateTextStyle: isDeactivated
                        ? deactivatedDateStyle
                        : isSelected
                            ? selectedDateStyle
                            : widget.dateTextStyle,
                    dayTextStyle: isDeactivated
                        ? deactivatedDayStyle
                        : isSelected
                            ? selectedDayStyle
                            : widget.dayTextStyle,
                    width: widget.width,
                    locale: widget.locale,
                    selectionColor:
                        isSelected ? widget.selectionColor : Colors.transparent,
                    onDateSelected: (selectedDate) {
                      // Don't notify listener if date is deactivated
                      if (isDeactivated) return;

                      // A date is selected
                      widget.onDateChange?.call(selectedDate);

                      setState(() {
                        _currentDate = selectedDate;
                      });

                      // Animate scroll to center the selected date if enabled
                      if (widget.centerSelectedDate) {
                        _animateToCenter(selectedDate);
                      }
                    },
                  );
                case CalendarType.persianDate:
                  return PersianDateWidget(
                    date: date,
                    monthTextStyle: isDeactivated
                        ? deactivatedMonthStyle
                        : isSelected
                            ? selectedMonthStyle
                            : widget.monthTextStyle,
                    dateTextStyle: isDeactivated
                        ? deactivatedDateStyle
                        : isSelected
                            ? selectedDateStyle
                            : widget.dateTextStyle,
                    dayTextStyle: isDeactivated
                        ? deactivatedDayStyle
                        : isSelected
                            ? selectedDayStyle
                            : widget.dayTextStyle,
                    width: widget.width,
                    locale: widget.locale,
                    selectionColor:
                        isSelected ? widget.selectionColor : Colors.transparent,
                    onDateSelected: (selectedDate) {
                      // Don't notify listener if date is deactivated
                      if (isDeactivated) return;

                      // A date is selected
                      widget.onDateChange?.call(selectedDate);

                      setState(() {
                        _currentDate = selectedDate;
                      });

                      // Animate scroll to center the selected date if enabled
                      if (widget.centerSelectedDate) {
                        _animateToCenter(selectedDate);
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class DatePickerController {
  _DatePickerState? _datePickerState;

  void setDatePickerState(_DatePickerState state) {
    _datePickerState = state;
  }

  void jumpToSelection() {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    if (_datePickerState!.widget.centerSelectedDate) {
      _datePickerState!._jumpToCenter(_datePickerState!._currentDate!);
    } else {
      _datePickerState!._controller.jumpTo(_datePickerState!
          ._calculateDateOffset(_datePickerState!._currentDate!));
    }
  }

  /// This function will animate the Timeline to the currently selected Date
  void animateToSelection(
      {duration = const Duration(milliseconds: 500), curve = Curves.linear}) {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    if (_datePickerState!.widget.centerSelectedDate) {
      _datePickerState!._animateToCenter(_datePickerState!._currentDate!);
    } else {
      _datePickerState!._controller.animateTo(
          _datePickerState!
              ._calculateDateOffset(_datePickerState!._currentDate!),
          duration: duration,
          curve: curve);
    }
  }

  /// This function will animate to any date that is passed as an argument
  /// In case a date is out of range nothing will happen
  void animateToDate(DateTime date,
      {duration = const Duration(milliseconds: 500), curve = Curves.linear}) {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    if (_datePickerState!.widget.centerSelectedDate) {
      _datePickerState!._animateToCenter(date);
    } else {
      _datePickerState!._controller.animateTo(
          _datePickerState!._calculateDateOffset(date),
          duration: duration,
          curve: curve);
    }
  }

  /// This function will animate to any date that is passed as an argument
  /// this will also set that date as the current selected date
  void setDateAndAnimate(DateTime date,
      {duration = const Duration(milliseconds: 500), curve = Curves.linear}) {
    assert(_datePickerState != null,
        'DatePickerController is not attached to any DatePicker View.');

    if (date.compareTo(_datePickerState!.widget.startDate) >= 0 &&
        date.compareTo(_datePickerState!.widget.startDate
                .add(Duration(days: _datePickerState!.widget.daysCount))) <=
            0) {
      // date is in the range
      _datePickerState!._currentDate = date;

      if (_datePickerState!.widget.centerSelectedDate) {
        _datePickerState!._animateToCenter(date);
      } else {
        _datePickerState!._controller.animateTo(
          _datePickerState!._calculateDateOffset(date),
          duration: duration,
          curve: curve,
        );
      }
    }
  }
}
