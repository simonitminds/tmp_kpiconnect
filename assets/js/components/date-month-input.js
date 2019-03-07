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
      console.log(value);
      const value = moment(value)
      this.props.onChange(value);
    }
    this.setState({ date: value });
  }

  render() {
    const {
      model, field, labelText, value, name, onChange
    } = this.props;
    const fieldName = name === false ? "" : name || `${model}_${field}`;
    console.log(this.state.date)

    const years = () => {
      let firstYear = moment().year();
      let lastYear = firstYear + 5;
      return _.range(firstYear, lastYear);
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const mvalue = {year: this.state.date.year(), month: this.state.date.month()};

    const makeText = (m) => {
      let text;
      if (m && m.year && m.month) {
        text = months[m.month - 1] + ' ' + m.year;
      } else {
        text = "";
      }
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
          <input value={makeText(mvalue)} onClick={this.handleClickInput.bind(this)} />
        </div>
      </div>
    );
  }
}
