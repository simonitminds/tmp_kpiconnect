import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import moment from 'moment';
import DateInput from './date-input';
import TimeInput from './time-input';

class DateTimeInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedTime: props.value ? moment(props.value).utc() : null
    };
  }

  updateTime(time) {
    this.setState({ selectedTime: time });
  }

  render() {
    const { model, field, label, fieldName, portId, ports } = this.props;
    const { selectedTime } = this.state;

    return(
      <React.Fragment>
        <input type="hidden" name={`${fieldName}`} value={selectedTime || ""} />
        <div className="field is-horizontal has-margin-bottom-xs">
          <div className="field-label">
            <label className="label">{label}</label>
          </div>
          <div className="field-body">
            <div className="control">
              <DateInput value={selectedTime} model={model} field={field} onChange={this.updateTime.bind(this)} />
            </div>
            <div className="control">
              <TimeInput value={selectedTime} model={model} field={field} onChange={this.updateTime.bind(this)} />
            </div>
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default DateTimeInput;
