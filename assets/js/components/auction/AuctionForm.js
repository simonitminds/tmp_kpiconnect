import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import Datetime from 'react-datetime';

class AuctionForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected_port: props.auction.port_id || '',
      selected_vessel: props.auction.vessel_id || ''
    };
    this.handlePortChange = this.handlePortChange.bind(this);
    this.handleVesselChange = this.handleVesselChange.bind(this);
    this.handleDateChange = this.handleDateChange.bind(this);
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

  handlePortChange(e) {
    this.setState({ selected_port: e.target.value });
  }
  handleVesselChange(e) {
    this.setState({ selected_vessel: e.target.value });
  }

  input_field(model, field, labelText, value, opts) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
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

  dateselect_field(model, field, labelText, value, opts = {}) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
    return (
      <div className="field is-grouped">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
        <div className="control">
          <input
            className="input"
            type="date"
            name={`${model}[${field}][date]`}
            id={`${model}_${field}_date`}
            defaultValue={this.date_part(value)}
          />
        </div>
        <div className="control">
          <div className="select">
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
          </div>
        </div>
        <div className="control">
          <div className="select">
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

  select_field(model, field, labelText, value, values, opts = {}) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
    return (
      <div className="field">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
        <div className="control">
          <div className="select">
            <select id={`${model}_${field}`} name={`${model}[${field}]`} value={value} onChange={this.handlePortChange}>
              <option disabled value="">
                Please select
              </option>
              {_.map(values, port => (
                <option key={port.id} value={port.id}>
                  {port.name}, {port.country}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>
    );
  }

  checkbox_field(model, field, labelText, value, opts = {}) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
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

  handleDateChange(date) {
    this.setState({
      startDate: date
    });
  }

  render() {
    return (
      <div>
        <div className="field">
          <label htmlFor="auction_vessel_id" className="label">
            Vessel
          </label>
          <div className="control">
            <div className="select">
              <select
                id="auction_vessel_id"
                name="auction[vessel_id]"
                value={this.state.selected_vessel}
                onChange={this.handleVesselChange}
              >
                <option disabled value="">
                  Please select
                </option>
                {_.map(this.props.vessels, vessel => (
                  <option key={vessel.id} value={vessel.id}>
                    {vessel.name}, {vessel.imo}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="field">
          <label htmlFor="auction_port_id" className="label">
            Port
          </label>
          <div className="control">
            <div className="select">
              <select
                id="auction_port_id"
                name="auction[port_id]"
                value={this.state.selected_port}
                onChange={this.handlePortChange}
              >
                <option disabled value="">
                  Please select
                </option>
                {_.map(this.props.ports, port => (
                  <option key={port.id} value={port.id}>
                    {port.name}, {port.country}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <Datetime dateFormat="DD/MM/YYYY" timeFormat={false} />
        {this.input_field('auction', 'company', 'company', this.props.auction.company)}
        {this.input_field('auction', 'po', 'po', this.props.auction.po, { labelClass: 'label is-uppercase' })}
        {this.dateselect_field('auction', 'eta', 'eta', this.props.auction.eta, { labelClass: 'label is-uppercase' })}
        {this.dateselect_field('auction', 'etd', 'etd', this.props.auction.etd, { labelClass: 'label is-uppercase' })}
        {this.dateselect_field('auction', 'auction_start', 'auction start', this.props.auction.auction_start, {
          labelClass: 'label is-capitalized'
        })}

        <div className="field">
          <label htmlFor="auction_duration" className="label">
            Duration
          </label>
          <div className="control">
            <div className="select">
              <select id="auction_duration" name="auction[duration]" defaultValue={this.props.auction.duration}>
                <option disabled value="">
                  Please select
                </option>
                <option value="10">10</option>
                <option value="15">15</option>
                <option value="20">20</option>
              </select>
            </div>
          </div>
        </div>

        {this.checkbox_field(
          'auction',
          'anonymous_bidding',
          'anonymous bidding',
          this.props.auction.anonymous_bidding,
          {
            labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'
          }
        )}
      </div>
    );
  }
}

export default AuctionForm;
