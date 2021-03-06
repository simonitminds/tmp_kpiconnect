import React from 'react';
import _ from 'lodash';
import InputField from '../input-field';
import InputErrors from '../input-errors';
import CheckBoxField from '../check-box-field';
import DateInput from '../date-input';
import TimeInput from '../time-input';
import SupplierList  from './common/forms/supplier-list';
import VesselFuelForm from './spot/forms/vessel-fuel-form';
import SpotAuctionForm from './spot/forms/spot-auction-form';
import TermAuctionForm from './term/forms/term-auction-form';

const Form = (props) => {
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
    fuel_indexes,
    current_index_price,
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
    updateMonth,
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
      return(<TermAuctionForm {...props} />);
    case 'formula_related':
      return(<TermAuctionForm {...props} hasFuelIndex={true} />);
    }
  };

  return (
    <div>
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
                  <div className="control has-margin-right-sm">
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

export default Form;
