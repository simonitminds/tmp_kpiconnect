import React from 'react';
import Picker from 'react-month-picker';
import moment from 'moment';
import _ from 'lodash';

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
    this.refs.pickAMonth.show()
  }
  handleAMonthChange(value, text) {
    //
  }
  handAMonthDismiss(value, onChange) {
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
    console.log(fieldName);
    const years = () => {
      let firstYear = moment().year();
      let lastYear = firstYear + 5;
      return _.range(firstYear, lastYear);
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    console.log(this.state.date.month());
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
        <div className={`control qa-${model}_${field}`}>
          <Picker
            id={fieldName}
            ref='pickAMonth'
            years={years()}
            lang={months}
            value={mvalue}
            onChange={this.handleAMonthChange.bind(this)}
            onDismiss={this.handAMonthDismiss.bind(this)}
          />
          <input value={makeText(mvalue)} onClick={this.handleClickInput.bind(this)} readOnly={true} />
        </div>
      </div>
    );
  }
}
