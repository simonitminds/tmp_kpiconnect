import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import InputField from '../input-field';
import CheckBoxField from '../check-box-field';
import DateInput from '../date-input';
import TimeInput from '../time-input';
import { portLocalTime } from '../../utilities';
import SupplierList  from './supplier-list';

const AuctionForm = (props) => {
  const {
    auction,
    deselectAllSuppliers,
    eta_date,
    eta_time,
    etd_date,
    etd_time,
    fuels,
    ports,
    scheduled_start_date,
    scheduled_start_time,
    selectAllSuppliers,
    selectPort,
    selectedSuppliers,
    suppliers,
    toggleSupplier,
    updateDate,
    updateInformation,
    updateInformationFromCheckbox,
    vessels,
    credit_margin_amount
  } = props;

  const vesselFuel0 = auction.vessel_fuels[0] || {};
  const vesselFuel1 = auction.vessel_fuels[1] || {};
  const port_id = auction.port_id ? auction.port_id : "";
  const selectedPort = _.chain(ports)
                        .filter(['id', auction.port_id])
                        .first()
                        .value();

  const portAgentDisplay = () => {
    if (auction.port_id) {
      return <InputField
        model={'auction'}
        field={'port_agent'}
        labelText={'Port Agent'}
        value={auction.port_agent}
        opts={{type: 'text'}}
        onChange={updateInformation.bind(this, 'auction.port_agent')}
        isHorizontal={true}
      />;
    }
  };

  return (
    <div>
      <input type="hidden" name="auction[scheduled_start]" className="qa-auction-scheduled_start" value={auction.scheduled_start ? moment(auction.scheduled_start).utc() : ""} />
      <input type="hidden" name="auction[eta]" className="qa-auction-eta" value={auction.eta ? moment(auction.eta).utc() : ""} />
      <input type="hidden" name="auction[etd]" className="qa-auction-etd" value={auction.etd ? moment(auction.etd).utc() : ""} />

      <section className="auction-info"> {/* Port info */}
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Arrival / Departure</legend>
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
                        className="qa-auction-port_id"
                        value={port_id}
                        onChange={selectPort.bind(this)}
                      >
                        <option disabled value="">
                          Please select
                        </option>
                        {_.map(ports, port => (
                          <option key={port.id} value={port.id}>
                            {port.name}, {port.country}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              <div className="field is-horizontal">

                <div className="field-label">
                  <label className="label">ETA</label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <DateInput value={auction.eta} model={'auction'} field={'eta'} labelText={'ETA'} onChange={updateDate.bind(this, 'eta_date')} />
                  </div>
                  <div className="control">
                    <TimeInput value={auction.eta} model={'auction'} field={'eta'} labelText={'ETA'} onChange={updateDate.bind(this, 'eta_time')} />
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label"></div>
                <div className="field-body">
                  <div className="control">
                    <i className="is-caption">Port Local Time: {portLocalTime(auction.eta, port_id, ports)}</i>
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label">
                  <label className="label">ETD</label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <DateInput value={auction.etd} model={'auction'} field={'etd'} labelText={'ETD'} onChange={updateDate.bind(this, 'etd_date')} />
                  </div>
                  <div className="control">
                    <TimeInput value={auction.etd} model={'auction'} field={'etd'} labelText={'ETD'} onChange={updateDate.bind(this, 'etd_time')} />
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label"></div>
                <div className="field-body">
                  <div className="control">
                    <i className="is-caption">Port Local Time: {portLocalTime(auction.etd, port_id, ports)}</i>
                  </div>
                </div>
              </div>
              {portAgentDisplay()}
            </fieldset>
          </div>
        </div>
      </section> {/* Port info */}

      <SupplierList onDeSelectAllSuppliers={deselectAllSuppliers}
                    onSelectAllSuppliers={selectAllSuppliers}
                    onToggleSupplier={toggleSupplier}
                    selectedPort={selectedPort}
                    selectedSuppliers={selectedSuppliers}
                    suppliers={suppliers} />

      <section className="auction-info"> {/* Fuel info */}
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Fuel 1</legend>
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
                        id="auction_vessel_id_0"
                        name="auction[auction_vessel_fuels][0][vessel_id]"
                        className="qa-auction-vessel_fuel-0-vessel_id"
                        value={vesselFuel0.vessel_id || ""}
                        onChange={updateInformation.bind(this, 'auction.vessel_fuels.0.vessel_id')} > <option disabled value="">
                          Please select
                        </option>
                        {_.map(vessels, vessel => (
                          <option key={vessel.id} value={vessel.id}>
                            {vessel.name}, {vessel.imo}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              </div>

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
                        id="auction_fuel_id_0"
                        name="auction[auction_vessel_fuels][0][fuel_id]"
                        className="qa-auction-vessel_fuel-0-fuel_id"
                        value={vesselFuel0.fuel_id || ""}
                        onChange={updateInformation.bind(this, 'auction.vessel_fuels.0.fuel_id')}
                      >
                        <option disabled value="">
                          Please select
                        </option>
                        {_.map(fuels, fuel => (
                          <option key={fuel.id} value={fuel.id}>
                            {fuel.name}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div> </div>
              </div>

              <InputField
                model={'auction'}
                field={'auction_vessel_fuels][0][quantity'}
                labelText={'Fuel Quantity (MT)'}
                value="FIX ME"
                isHorizontal={true}
                opts={{type: 'number', name: 'vessel_fuel-0-quantity'}}
                onChange={updateInformation.bind(this, 'auction.vessel_fuels.0.quantity')}
              />
            </fieldset>


            <fieldset>
              <legend className="subtitle is-4" >Fuel 2</legend>
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
                        id="auction_vessel_id_1"
                        name="auction[auction_vessel_fuels][1][vessel_id]"
                        className="qa-auction-vessel_fuel-1-vessel_id"
                        value={vesselFuel1.vessel_id || ""}
                        onChange={updateInformation.bind(this, 'auction.vessel_fuels.1.vessel_id')} > <option disabled value="">
                          Please select
                        </option>
                        {_.map(vessels, vessel => (
                          <option key={vessel.id} value={vessel.id}>
                            {vessel.name}, {vessel.imo}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              </div>

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
                        id="auction_fuel_id_1"
                        name="auction[auction_vessel_fuels][1][fuel_id]"
                        className="qa-auction-vessel_fuel-1-fuel_id"
                        value={vesselFuel1.fuel_id || ""}
                        onChange={updateInformation.bind(this, 'auction.vessel_fuels.1.fuel_id')}
                      >
                        <option disabled value="">
                          Please select
                        </option>
                        {_.map(fuels, fuel => (
                          <option key={fuel.id} value={fuel.id}>
                            {fuel.name}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div> </div>
              </div>

              <InputField
                model={'auction'}
                field={'auction_vessel_fuels][1][quantity'}
                labelText={'Fuel Quantity (MT)'}
                value="FIX ME"
                isHorizontal={true}
                opts={{type: 'number', name: 'vessel_fuel-1-quantity'}}
                onChange={updateInformation.bind(this, 'auction.vessel_fuels.1.quantity')}
              />
            </fieldset>
          </div>
        </div>
      </section> {/* Fuel info */}

      <section className="auction-info"> {/* Add'l info */}
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Additional Information</legend>

              <div className="field is-horizontal">
                  <textarea
                    name={'auction[additional_information]'}
                    id={'auction_additional_information'}
                    className="textarea qa-auction-additional_information"
                    defaultValue={auction.additional_information}
                    onChange={updateInformation.bind(this, 'auction.additional_information')}
                  ></textarea>
              </div>
            </fieldset>
          </div>
        </div>
      </section> {/* Add'l info */}

      <section className="auction-info"> {/* Auction details */}
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Auction Details</legend>

              <InputField
                model={'auction'}
                field={'po'}
                labelText={'po'}
                value={auction.po}
                isHorizontal={true}
                opts={{ labelClass: 'label is-uppercase' }}
                onChange={updateInformation.bind(this, 'auction.po')}
              />

              <div className="field is-horizontal">
                <div className="field-label">
                  <label className="label">Auction Start</label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <DateInput value={auction.scheduled_start} model={'auction'} field={'scheduled_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'scheduled_start_date')} />
                  </div>
                  <div className="control">
                    <TimeInput value={auction.scheduled_start} model={'auction'} field={'scheduled_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'scheduled_start_time')} />
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label"></div>
                <div className="field-body">
                  <div className="control">
                    <i className="is-caption">Port Local Time: {portLocalTime(auction.scheduled_start, port_id, ports)}</i>
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
                      <select id="auction_duration" name="auction[duration]" defaultValue={auction.duration / 60000} className="qa-auction-duration" onChange={updateInformation.bind(this, 'auction.duration')}>
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
                <div className="field-label">
                  <label htmlFor="auction_decision_duration" className="label">
                    Decision Duration
                  </label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <div className="select">
                      <select id="auction_decision_duration" name="auction[decision_duration]" defaultValue={auction.decision_duration / 60000} className="qa-auction-decision_duration" onChange={updateInformation.bind(this, 'auction.decision_duration')}>
                        <option disabled value="">
                          Please select
                        </option>
                        <option value="15">15</option>
                        <option value="10">10</option>
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
                      value={auction.anonymous_bidding}
                      opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                      onChange={updateInformation.bind(this, 'auction.anonymous_bidding')}
                  />
                </div>
              </div>

              { (credit_margin_amount != 0) &&
                  <div className="field is-horizontal">
                    <div className="field-label"></div>
                    <div className="field-body field-body--columned">
                      <CheckBoxField
                          model={'auction'}
                          field={'is_traded_bid_allowed'}
                          labelText={'accept traded bids'}
                          value={auction.is_traded_bid_allowed}
                          opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                          onChange={updateInformationFromCheckbox.bind(this, 'auction.is_traded_bid_allowed')}
                      />
                      <div className="field-body__note" style={{display: auction.is_traded_bid_allowed === true ? `inline-block` : `none`}}><strong>Your Credit Margin Amount:</strong> $<span className="qa-auction-credit_margin_amount">{credit_margin_amount}</span></div>
                    </div>
                  </div>
              }

              <div className="field is-horizontal">
                <div className="field-label"></div>
                <div className="field-body">
                  <CheckBoxField
                      model={'auction'}
                      field={'split_bid_allowed'}
                      labelText={'allow split bidding'}
                      value={auction.allow_split_bidding}
                      opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                      onChange={updateInformation.bind(this, 'auction.split_bid_allowed')}
                  />
                </div>
              </div>
            </fieldset>
          </div>
        </div>
      </section> {/* Auction details */}
    </div>
  );
}

export default AuctionForm;
