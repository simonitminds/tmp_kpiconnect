import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import InputField from '../../../input-field';
import InputErrors from '../../../input-errors';
import CheckBoxField from '../../../check-box-field';

const TermFuelFormSection = (props) => {
  const {
    auction,
    errors,
    fuels,
    totalFuelVolume,
    updateInformation,
    updateInformationFromCheckbox
  } = props;

  const calculateTotalFuelVolume = () => {
    let fuelQuantity;
    let startDate;
    let endDate;
    if (document.getElementById('auction_fuel_quantity')) {
      fuelQuantity = document.getElementById('auction_fuel_quantity').value;
    } else {
      fuelQuantity = 0;
    }
    if (document.getElementById('auction_start_date_date')) {
      startDate = moment(document.getElementById('auction_start_date_date').value);
    } else {
      startDate = moment();
    }
    if (document.getElementById('auction_end_date_date')) {
      endDate = moment(document.getElementById('auction_end_date_date').value);
    } else {
      endDate = moment().add(1, 'months');
    }

    let months = endDate.diff(startDate, 'months');

    if (fuelQuantity && months) {
      return fuelQuantity * months;
    } else {
      return "—";
    }
  }


  return (
    <section className="auction-info is-gray-1"> {/* Fuel info */}
      <div className="container">
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
                <div className="control has-margin-right-sm">
                  <div className="select is-fullwidth">
                    <select
                      id="auction_fuel_id"
                      name="auction[fuel_id]"
                      className="qa-auction-select-fuel"
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
                </div>
                <InputErrors errors={errors.fuel_id} />
              </div>
            </div>

            <InputField
              model={'auction'}
              field={'fuel_quantity'}
              labelText={'Fuel Quantity per Month (MT)'}
              value={auction.fuel_quantity}
              errors={errors.fuel_quantity}
              isHorizontal={true}
              opts={{type: 'number'}}
              onChange={updateInformation.bind(this, 'auction.fuel_quantity')}
            />

            <div className="field is-horizontal">
              <div className="field-label"></div>
              <div className="field-body field-body--columned">
                <CheckBoxField
                    model={'auction'}
                    field={'show_total_fuel_volume'}
                    labelText={'purchase as complete lot'}
                    defaultChecked={false}
                    opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                    onChange={updateInformationFromCheckbox.bind(this, 'auction.show_total_fuel_volume')}
                    className={'has-margin-right-sm'}
                />
                <InputErrors errors={errors.show_total_fuel_volume} />
                  <div className="field-body__note" style={{display: auction.show_total_fuel_volume === true ? `inline-block` : `none`}}>
                    <strong>Your Total Volume:</strong>
                    <span className="qa-auction-total_fuel_volume">{calculateTotalFuelVolume()}</span> MT
                  </div>
              </div>
            </div>

          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default TermFuelFormSection;
