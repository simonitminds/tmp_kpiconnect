import React from 'react';
import Datetime from 'react-datetime';
import { Component } from 'react';

export default class DateAndTime extends React.Component {
  constructor(props) {
    super(props);
  }
  render(){
    return(
      <div className={`field is-grouped qa-${this.props.model}-${this.props.field}`}>
        <label htmlFor={`${this.props.model}_${this.props.field}`} className="label">
          {this.props.labelText}
        </label>
        <div className="control">
          <Datetime
            dateFormat="DD/MM/YYYY"
            inputProps={{
            }}
            timeFormat={false}
            utc={true}
            value={this.props.value}
            onChange={e => this.props.onChange(this.props.field, e)}
            closeOnSelect={true}
          />
        </div>
        <div className="control">
          <Datetime
            timeFormat={"H:mm"}
            utc={true}
            timeConstraints={{minutes: {step: 5}}}
            value={this.props.value}
            onChange={e => this.props.onChange(this.props.field, e)}
            dateFormat={false}
            closeOnSelect={true}
          />
        </div>
      </div>
    );
  }
 }
