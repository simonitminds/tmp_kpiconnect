import React from 'react';
import 'react-dates/initialize';
import { DateRangePicker } from 'react-dates';
import moment from 'moment';

class DateRangeInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      startDate: props.startDate ? moment(props.startDate).utc() : null,
      endDate: props.endDate ? moment(props.endDate).utc() : null,
      focusedInput: null
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.startDate !== prevProps.startDate && this.props.endDate !== prevProps.endDate) {
      this.setState({
        startDate: this.props.startDate ? moment(this.props.startDate).utc() : null,
        endDate: this.props.endDate ? moment(this.props.endDate).utc() : null,
        focusedInput: null
      });
    }
  }

  onDatesChange({ startDate, endDate }) {
    this.setState({ startDate, endDate });
    this.props.onChange({ startDate, endDate });
  }

  render() {
    const { focusedInput, startDate, endDate } = this.state;

    return (
      <div>
        <DateRangePicker
          orientation={this.props.orientation ? this.props.orientation : "horizontal"}
          onDatesChange={this.onDatesChange.bind(this)}
          onFocusChange={(focusedInput) => this.setState({ focusedInput })}
          focusedInput={focusedInput}
          startDate={startDate}
          endDate={endDate}
          customArrowIcon={
            <i className="has-margin-left-sm has-margin-right-sm fas fa-arrow-right"></i>
          }
          startDateId={'startDate'}
          endDateId={'endDate'}
          isOutsideRange={() => false}
        />
      </div>
    );
  }
}

export default DateRangeInput;
