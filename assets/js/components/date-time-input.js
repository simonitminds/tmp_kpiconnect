import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import moment from 'moment';
import { portLocalTime } from '../utilities';
import DateInput from './date-input';
import TimeInput from './time-input';

class DateTimeInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedTime: moment(props.value).utc()
    };
  }

  updateTime(time) {
    this.setState({ selectedTime: time });
  }

  render() {
    const { label, fieldName, portId, ports } = this.props;
    const { selectedTime } = this.state;

    return(
      <React.Fragment>
        <input type="hidden" name={`${fieldName}`} value={selectedTime} />
        <div className="field is-horizontal">
          <div className="field-label">
            <label className="label">{label}</label>
          </div>
          <div className="field-body">
            <div className="control">
              <DateInput value={selectedTime} name={false} onChange={this.updateTime.bind(this)} />
            </div>
            <div className="control">
              <TimeInput value={selectedTime} name={false} onChange={this.updateTime.bind(this)} />
            </div>
            <i className="help">Port Local Time: {portLocalTime(selectedTime, portId, ports)}</i>
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default DateTimeInput;
