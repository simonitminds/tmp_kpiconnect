import _ from 'lodash';
import React from 'react';
import TimePicker from 'rc-time-picker';
import moment from 'moment';

export default class TimeInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      time: props.value ? moment(props.value).utc() : null
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value) {
      this.setState({
        time: this.props.value ? moment(this.props.value).utc() : null
      })
    }
  }

  render(){
    const {
      model, field, labelText, onChange
    } = this.props;

    const {time} = this.state;

    const currentDate = moment();

    const disabledHours = () => {
      if (time === null || time.isBefore(currentDate, 'day')) {
        return _.range(0, 25);
      } else if (time.isSame(currentDate, 'day')) {
        return _.range(currentDate.hour());
      }
      return [];
    }

    const disabledMinutes = (selectedHour) => {
      if (time === null || time.isBefore(currentDate, 'day')) {
        return _.range(0, 61);
      }

      if (time.isAfter(currentDate, 'day')) {
        return [];
      }

      if (time.hour() == selectedHour) {
        return _.range(currentDate.minute());
      } else if (time.hour() < selectedHour) {
        return _.range(0, 61);
      }

      return [];
    }

    return(
      <div className={`qa-${model}-${field}_time`}>
        <TimePicker
          id={`${model}_${field}_time`}
          value={this.state.time}
          showSecond={false}
          minuteStep={5}
          allowEmpty={true}
          onChange={value => {
              onChange(value);
              this.setState({ time: value });
            }
          }
          disabledHours={disabledHours}
          disabledMinutes={disabledMinutes}
        />
      </div>
    );
  }
}
