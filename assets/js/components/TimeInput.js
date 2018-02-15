import React from 'react';
import TimePicker from 'rc-time-picker';
import moment from 'moment';

export default class TimeInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      time: moment(props.value).utc()
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value) {
      this.setState({
        time: moment(this.props.value).utc()
      })
    }
  }

  render(){
    const {
      model, field, labelText, onChange
    } = this.props;

    return(
      <div className={`control qa-${model}-${field}_time`}>
        <TimePicker
          id={`${model}_${field}_time`}
          value={this.state.time || "00:00"}
          showSecond={false}
          minuteStep={5}
          onChange={value => {
              onChange(value);
              this.setState({ time: value });
            }
          }
        />
      </div>
    );
  }
}
