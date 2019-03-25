import React from 'react';
import Picker from 'react-month-picker';
import moment from 'moment';
import _ from 'lodash';
import { formatMonthYear } from '../utilities';

export default class DateMonthInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      date: props.value ? moment(props.value).utc() : null,
      focused: false
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value) {
      this.setState({
        date: this.props.value ? moment(this.props.value).utc() : moment().utc()
      })
    }
  }

  handleClickInput(e) {
    this.refs.monthPicker.show()
  }
  handleMonthChange(year, month) {
    const value = {year: year, month: month};
    if (value) {
      const newValue = {year: value.year, month: value.month - 1}
      this.props.onChange(newValue);
    }
    this.setState({ date: moment(value).utc() });
  }

  render() {
    const {
      model, field, labelText, value, name, onChange, defaultValue
    } = this.props;
    const fieldName = name === false ? "" : name || `${model}_${field}`;
    const years = () => {
      let firstYear = moment().year();
      let lastYear = firstYear + 5;
      return _.range(firstYear, lastYear);
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const mvalue = {year: this.state.date.year(), month: this.state.date.month()};

    const makeText = (date) => {
      let text;
      if (date && date.year && date.month) {
        text = months[date.month] + ' ' + date.year;
      } else {
        text = "";
      }
      return text;
    }

    return(
      <div className="has-margin-right-sm">
        <div className={`control`}>
          <Picker
            ref='monthPicker'
            years={years()}
            lang={months}
            value={{year: mvalue.year, month: mvalue.month + 1}}
            defaultValue={value}
            onChange={this.handleMonthChange.bind(this)}
            // onDismiss={this.handleMonthDismiss.bind(this)}
          />
          <input
            className={`input`}
            value={formatMonthYear(mvalue)}
            onClick={this.handleClickInput.bind(this)}
             />
        </div>
      </div>
    );
  }
}
