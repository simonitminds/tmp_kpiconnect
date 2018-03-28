import React from 'react';
import 'react-dates/initialize';
import { SingleDatePicker } from 'react-dates';
import moment from 'moment';

export default class DateInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      date: moment(props.value).utc(),
      focused: false,
      numberOfMonths: 1
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value) {
      this.setState({
        date: moment(this.props.value).utc()
      })
    }
  }

  render(){
    const {
      model, field, labelText, value, onChange
    } = this.props;

    return(
      <div>
        {/* <label htmlFor={`${model}_${field}`} className="label">
          {labelText}
        </label> */}
        <div className={`control qa-${model}-${field}_date`}>
          <SingleDatePicker
            id={`${model}_${field}_date`}
            date={this.state.date}
            onDateChange={date => {
                if (date) {
                  onChange(date);
                }
                this.setState({ date });
              }
            }
            focused={this.state.focused}
            numberOfMonths={this.state.numberOfMonths}
            onFocusChange={({ focused }) => this.setState({ focused })}
          />
        </div>
      </div>
    );
  }
}
