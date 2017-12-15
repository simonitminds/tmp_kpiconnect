import React from 'react';
import _ from 'lodash';
import moment from 'moment';

class AuctionForm extends React.Component {
  constructor(props) {
    super(props);
  }

  date_part(datetime) {
    return moment(datetime).format('YYYY-MM-DD');
  }

  hour_part(datetime) {
    return moment(datetime).format('HH');
  }

  minute_part(datetime) {
    return moment(datetime).format('mm');
  }

  padLeft(num) {
    const str = num.toString();
    return ('00' + str).substring(str.length);
  }

  input_field(model, field, value, opts) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(field);
    return (
      <div className="field">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
        <div className="control">
          <input
            type="text"
            name={`${model}[${field}]`}
            id={`${model}_${field}`}
            className="input"
            defaultValue={value}
            autoComplete="off"
          />
        </div>
      </div>
    );
  }

  dateselect_field(model, field, value, opts = {}) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(field);
    return (
      <div className="field">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
        <div className="control">
          <div className="select is-flex is-datepicker">
            <input
              type="date"
              name={`${model}[${field}][date]`}
              id={`${model}_${field}_date`}
              defaultValue={this.date_part(value)}
            />
            <select
              id={`${model}_${field}_hour`}
              name={`${model}[${field}][hour]`}
              defaultValue={this.hour_part(value)}
            >
              {_.map(_.range(24), hour => (
                <option key={hour} value={this.padLeft(hour)}>
                  {this.padLeft(hour)}
                </option>
              ))}
            </select>

            <select
              id={`${model}_${field}_minute`}
              name={`${model}[${field}][minute]`}
              defaultValue={this.minute_part(value)}
            >
              {_.map(_.range(60), minutes => (
                <option key={minutes} value={this.padLeft(minutes)}>
                  {this.padLeft(minutes)}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>
    );
  }

  checkbox_field(model, field, value, opts = {}) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(field);
    return (
      <div className="field">
        <div className="control">
          <input name={`${model}[${field}]`} type="hidden" value="false" />
          <input
            className="checkbox"
            id={`${model}_${field}`}
            name={`${model}[${field}]`}
            type="checkbox"
            value="true"
          />
          <label htmlFor={`${model}_${field}`} className={labelClass}>
            {labelDisplay}
          </label>
        </div>
      </div>
    );
  }

  render() {
    return (
      <div>
        {this.input_field('auction', 'vessel', this.props.auction.vessel)}
        {this.input_field('auction', 'port', this.props.auction.port)}
        {this.input_field('auction', 'company', this.props.auction.company)}
        {this.input_field('auction', 'po', this.props.auction.po, { labelClass: 'label is-uppercase' })}
        {this.dateselect_field('auction', 'eta', this.props.auction.eta, { labelClass: 'label is-uppercase' })}
        {this.dateselect_field('auction', 'etd', this.props.auction.etd, { labelClass: 'label is-uppercase' })}
        {this.dateselect_field('auction', 'auction_start', this.props.auction.auction_start, {
          labelClass: 'label is-capitalized'
        })}
        {this.input_field('auction', 'duration', this.props.auction.duration)}
        {this.checkbox_field('auction', 'anonymous_bidding', this.props.auction.anonymous_bidding, {
          labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'
        })}
      </div>
    );
  }
}

export default AuctionForm;
