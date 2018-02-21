import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import { Component } from 'react';
import InputField from '../InputField';
import CheckBoxField from '../CheckBoxField';
import DateInput from '../DateInput';
import TimeInput from '../TimeInput';
import { portLocalTime } from '../../utilities';
import SupplierList  from './SupplierList';

const AuctionForm = (props) => {
  const {
    auction,
    auction_start_date,
    auction_start_time,
    eta_date,
    eta_time,
    etd_date,
    etd_time,
    fuels,
    ports,
    vessels,
    updateDate,
    updateInformation,
    selectedSuppliers,
    suppliers,
    selectPort,
    toggleSupplier,
    selectAllSuppliers,
    deselectAllSuppliers,
  } = props;

  const port_id = _.get(auction, 'port.id', "");
  const selectedPort = _.chain(ports)
                        .filter(['id', auction.port_id])
                        .first()
                        .value();

  return (
    <div>
      <input type="hidden" name="auction[auction_start]" className="qa-auction-auction_start" value={moment(auction.auction_start).utc()} />
      <input type="hidden" name="auction[eta]" className="qa-auction-eta" value={moment(auction.eta).utc()} />
      <input type="hidden" name="auction[etd]" className="qa-auction-etd" value={moment(auction.etd).utc()} />

      <section className="auction-info"> {/* Vessel info */}
        <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg"> <div className="content">
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
                        className="qa-auction-vessel_id"
                        value={auction.vessel_id}
                        onChange={updateInformation.bind(this, 'auction.vessel_id')} > <option disabled value="">
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
            </fieldset>
          </div>
        </div>
      </section> {/* Vessel info */}

      <section className="auction-info"> {/* Port info */}
        <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
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
                        value={auction.port_id}
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
                        className="qa-auction-fuel_id"
                        value={auction.fuel_id}
                        onChange={updateInformation.bind(this, 'auction.fuel_id')}
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
                field={'fuel_quantity'}
                labelText={'Fuel Quantity (MT)'}
                value={auction.fuel_quantity}
                opts={{type: 'number', label: "Fuel Quantity (MT)"}}
                onChange={updateInformation.bind(this, 'auction.fuel_quantity')}
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
                    defaultValue={auction.additional_information}
                    onChange={updateInformation.bind(this, 'auction.additional_information')}
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
                value={auction.po}
                opts={{ labelClass: 'label is-uppercase' }}
                onChange={updateInformation.bind(this, 'auction.po')}
              />

              <div className="field is-horizontal">
                <div className="field-label">
                  <label className="label">Auction Start</label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <DateInput value={auction.auction_start} model={'auction'} field={'auction_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'auction_start_date')} />
                  </div>
                  <div className="control">
                    <TimeInput value={auction.auction_start} model={'auction'} field={'auction_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'auction_start_time')} />
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label"></div>
                <div className="field-body">
                  <div className="control">
                    <i className="is-caption">Port Local Time: {portLocalTime(auction.auction_start, port_id, ports)}</i>
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
            </fieldset>
          </div>
        </div>
      </section> {/* Auction details */}
    </div>
  );
}

export default AuctionForm;
