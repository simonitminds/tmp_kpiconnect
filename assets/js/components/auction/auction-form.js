import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import InputField from '../input-field';
import CheckBoxField from '../check-box-field';
import DateInput from '../date-input';
import TimeInput from '../time-input';
import { portLocalTime } from '../../utilities';
import SupplierList  from './supplier-list';
import VesselFuelForm from './vessel-fuel-form';

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
    credit_margin_amount,
  } = props;

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

      <section className="auction-info is-gray-1"> {/* Port info */}
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Arrival/Departure</legend>
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

     <VesselFuelForm auction={auction}
                     vessels={vessels}
                     fuels={fuels}
                     vessel_fuels={auction.vessel_fuels} />

      <section className="auction-info is-gray-1"> {/* Add'l info */}
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
                <div className="field-body field-body--distribute-middle">
                  <div className="control">
                    <DateInput value={auction.scheduled_start} model={'auction'} field={'scheduled_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'scheduled_start_date')} />
                  </div>
                  <div className="control">
                    <TimeInput value={auction.scheduled_start} model={'auction'} field={'scheduled_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'scheduled_start_time')} />
                  </div>
                  <div className="control has-text-gray-3">
                    (GMT)
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

              <div className="field is-horizontal has-margin-bottom-md">
                <div className="field-label"></div>
                <div className="field-body">
                  <CheckBoxField
                      model={'auction'}
                      field={'anonymous_bidding'}
                      labelText={'anonymous bidding'}
                      defaultChecked={auction.anonymous_bidding}
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
                          defaultChecked={auction.is_traded_bid_allowed}
                          opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                          onChange={updateInformationFromCheckbox.bind(this, 'auction.is_traded_bid_allowed')}
                      />
                      <div className="field-body__note" style={{display: auction.is_traded_bid_allowed === true ? `inline-block` : `none`}}><strong>Your Credit Margin Amount:</strong> $<span className="qa-auction-credit_margin_amount">{credit_margin_amount}</span></div>
                    </div>
                  </div>
              }
            </fieldset>
          </div>
        </div>
      </section> {/* Auction details */}
    </div>
  );
}

export default AuctionForm;
