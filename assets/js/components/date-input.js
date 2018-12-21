import React from 'react';
import 'react-dates/initialize';
import { SingleDatePicker } from 'react-dates';
import moment from 'moment';

export default class DateInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      date: props.value ? moment(props.value).utc() : null,
      focused: false,
      numberOfMonths: 1
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value) {
      this.setState({
        date: this.props.value ? moment(this.props.value).utc() : null
      })
    }
  }

  render(){
    const {
      model, field, labelText, value, name, onChange
    } = this.props;

    const fieldName = name === false ? "" : name || `${model}_${field}_date`;

    return(
      <div>
        {/* <label htmlFor={`${model}_${field}`} className="label">
          {labelText}
        </label> */}
        <div className={`control qa-${model}-${field}_date`}>
          <SingleDatePicker
            id={fieldName}
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
