import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import { Component } from 'react';
import InputField from '../InputField';
import CheckBoxField from '../CheckBoxField';
import DateAndTime from '../DateAndTime';
import { portLocalTime } from '../../utilities';

class AuctionForm extends React.Component {
  constructor(props) {
    super(props);
    console.log(props);
    this.state = {
      selected_port: props.auction.port_id || '',
      selected_vessel: props.auction.vessel_id || '',
      selected_fuel: props.auction.fuel_id || '',
      auction_start: this.setDate(props.auction.auction_start),
      eta: this.setDate(props.auction.eta),
      etd: this.setDate(props.auction.etd),
      additional_information: props.auction.additional_information || ''
    };
    this.handlePortChange = this.handlePortChange.bind(this);
    this.handleVesselChange = this.handleVesselChange.bind(this);
    this.handleFuelChange = this.handleFuelChange.bind(this);
    this.handleDateChange = this.handleDateChange.bind(this);
  }

  setDate(date) {
    let value = date || moment().hour(0).minute(0)
    return moment(value);
  }

  handlePortChange(e) {
    this.setState({ selected_port: e.target.value });
  }
  handleVesselChange(e) {
    this.setState({ selected_vessel: e.target.value });
  }
  handleFuelChange(e) {
    this.setState({ selected_fuel: e.target.value });
  }

  handleDateChange(field, date) {
    this.setState({
      [field]: moment(date)
    });
  }

  render() {
    return (
      <div>
        <input type="hidden" id="auction_auction_start_minute" name="auction[auction_start]" value={this.state.auction_start} />
        <input type="hidden" id="auction_eta_minute" name="auction[eta]" value={this.state.eta} />
        <input type="hidden" id="auction_etd_minute" name="auction[etd]" value={this.state.etd} />

        <section className="auction-info"> {/* Vessel info */}
          <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Vessel</legend>
                <div className="field is-horizontal">
                  <div className="field-label">
                    <label htmlFor="auction_vessel_id" className="label">
                      Vessel Name
                    </label>
                  </div>
                  <div className="field-body">
                    <div className="control">
                      <div className="select is-fullwidth">
                        <select
                          id="auction_vessel_id"
                          name="auction[vessel_id]"
                          className="qa-auction-vessel"
                          value={this.state.selected_vessel}
                          onChange={this.handleVesselChange} > <option disabled value="">
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
                </div>
              </fieldset>
            </div>
          </div>
        </section> {/* Vessel info */}

        <section className="auction-info"> {/* Port info */}
          <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Port</legend>
                <div className="field is-horizontal">
                  <div className="field-label">
                    <label htmlFor="auction_port_id" className="label">
                      Port
                    </label>
                  </div>
                  <div className="field-body">
                    <div className="control">
                      <div className="select is-fullwidth">
                        <select
                          id="auction_port_id"
                          name="auction[port_id]"
                          className="qa-auction-port"
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
                </div>

                <DateAndTime value={this.state.eta} model={'auction'} field={'eta'} labelText={'ETA'} onChange={this.handleDateChange} />
                <div className="field is-horizontal">
                  <div className="field-label"></div>
                  <div className="field-body">
                    <div className="control">
                      <i className="is-caption">Port Local Time: {portLocalTime(this.state.eta, this.state.selected_port, this.props.ports)}</i>
                    </div>
                  </div>
                </div>
                <DateAndTime value={this.state.etd} model={'auction'} field={'etd'} labelText={'ETD'} onChange={this.handleDateChange} />
                <div className="field is-horizontal">
                  <div className="field-label"></div>
                  <div className="field-body">
                    <div className="control">
                      <i className="is-caption">Port Local Time: {portLocalTime(this.state.etd, this.state.selected_port, this.props.ports)}</i>
                    </div>
                  </div>
                </div>
              </fieldset>
            </div>
          </div>
        </section> {/* Port info */}

        <section className="auction-info"> {/* Fuel info */}
          <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Fuel</legend>
                <div className="field is-horizontal">
                  <div className="field-label">
                    <label htmlFor="auction_fuel_id" className="label">
                      Fuel
                    </label>
                  </div>
                  <div className="field-body">
                    <div className="control">
                      <div className="select is-fullwidth">
                        <select
                          id="auction_fuel_id"
                          name="auction[fuel_id]"
                          className="qa-auction-fuel"
                          value={this.state.selected_fuel}
                          onChange={this.handleFuelChange}
                        >
                          <option disabled value="">
                            Please select
                          </option>
                          {_.map(this.props.fuels, fuel => (
                            <option key={fuel.id} value={fuel.id}>
                              {fuel.name}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                  </div>
                </div>

                <InputField
                  model={'auction'}
                  field={'fuel_quantity'}
                  labelText={'Fuel Quantity (MT)'}
                  value={this.props.auction.fuel_quantity}
                  opts={{type: 'number', label: "Fuel Quantity (MT)"}}
                />
              </fieldset>
            </div>
          </div>
        </section> {/* Fuel info */}

        <section className="auction-info"> {/* Add'l info */}
          <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Additional Information</legend>

                <div className="field is-horizontal">
                    <textarea
                      name={'auction[additional_information]'}
                      id={'auction_additional_information'}
                      className="textarea qa-auction-additional_information"
                      defaultValue={this.state.additional_information}
                    ></textarea>
                </div>
              </fieldset>
            </div>
          </div>
        </section> {/* Add'l info */}

        <section className="auction-info"> {/* Auction details */}
          <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Auction Details</legend>

                <InputField
                  model={'auction'}
                  field={'po'}
                  labelText={'po'}
                  value={this.props.auction.po}
                  opts={{ labelClass: 'label is-uppercase' }}
                />

                <DateAndTime value={this.state.auction_start} model={'auction'} field={'auction_start'} labelText={'Auction Start'} onChange={this.handleDateChange} />
                <div className="field is-horizontal">
                  <div className="field-label"></div>
                  <div className="field-body">
                    <div className="control">
                      <i className="is-caption">Port Local Time: {portLocalTime(this.state.auction_start, this.state.selected_port, this.props.ports)}</i>
                    </div>
                  </div>
                </div>

               <div className="field is-horizontal">
                 <div className="field-label">
                  <label htmlFor="auction_duration" className="label">
                    Duration
                  </label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <div className="select">
                      <select id="auction_duration" name="auction[duration]" defaultValue={this.props.auction.duration} className="qa-auction-duration">
                        <option disabled value="">
                          Please select
                        </option>
                        <option value="10">10</option>
                        <option value="15">15</option>
                        <option value="20">20</option>
                      </select>
                    </div>
                    <span className="select__extra-label">minutes</span>
                  </div>
                </div>
               </div>

               <div className="field is-horizontal">
                 <div className="field-label"></div>
                 <div className="field-body">
                   <CheckBoxField
                       model={'auction'}
                       field={'anonymous_bidding'}
                       labelText={'anonymous bidding'}
                       value={this.props.auction.anonymous_bidding}
                       opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                   />
                 </div>
               </div>
              </fieldset>
            </div>
          </div>
        </section> {/* Auction details */}
      </div>);
  }
}

export default AuctionForm;
