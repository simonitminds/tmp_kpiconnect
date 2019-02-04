import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import InputField from '../input-field';
import InputErrors from '../input-errors';
import CheckBoxField from '../check-box-field';
import DateInput from '../date-input';
import TimeInput from '../time-input';
import { portLocalTime } from '../../utilities';
import SupplierList  from './supplier-list';
import VesselFuelForm from './vessel-fuel-form';
import SpotAuctionForm from './forms/spot-auction-form';
import ForwardFixedAuctionForm from './forms/forward-fixed-auction-form';

const AuctionForm = (props) => {
  const {
    auction,
    errors,
    type,
    deselectAllSuppliers,
    credit_margin_amount,
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
    selectAuctionType,
    selectedSuppliers,
    suppliers,
    toggleSupplier,
    updateDate,
    updateInformation,
    updateInformationFromCheckbox,
    vessels,
  } = props;

  const auctionTypes = ["spot", "forward_fixed", "formula_related"];
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
        errors={errors.port_agent}
        opts={{type: 'text'}}
        onChange={updateInformation.bind(this, 'auction.port_agent')}
        isHorizontal={true}
      />;
    }
  };

  const renderFormContent = (type) => {
    switch(type) {
    case 'spot':
      return(<SpotAuctionForm {...props} />);
    case 'forward_fixed':
      return(<ForwardFixedAuctionForm {...props} />);
    case 'formula_related':
      return(<div>Formula Related</div>);
    }
  };

  return (
    <div>
      <input type="hidden" name="auction[scheduled_start]" className="qa-auction-scheduled_start" value={auction.scheduled_start ? moment(auction.scheduled_start).utc() : ""} />

      <section className="auction-info is-gray-1">
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Auction Type</legend>
              <div className="field is-horizontal">
                <div className="field-label">
                  <label htmlFor="auction_port_id" className="label">
                    Auction Type
                  </label>
                </div>
                <div className="field-body">
                  <div className="control">
                    <div className="select is-fullwidth">
                      <select
                        id="auction_type"
                        name="auction[type]"
                        className="qa-auction-type"
                        value={type}
                        onChange={selectAuctionType}
                      >
                        <option disabled value="">
                          Please select
                        </option>
                        {_.map(auctionTypes, type => (
                          <option key={type} value={type}>
                            {_.startCase(type)}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                  <InputErrors errors={errors.type} />
                </div>
              </div>
            </fieldset>
          </div>
        </div>
      </section>


      {renderFormContent(type)}
    </div>
  );
}

export default AuctionForm;
