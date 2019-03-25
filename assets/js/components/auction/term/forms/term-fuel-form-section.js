import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import InputField from '../../../input-field';
import InputErrors from '../../../input-errors';
import CheckBoxField from '../../../check-box-field';
import TermFuelIndexFormSection from './term-fuel-index-form-section';

const TermFuelFormSection = (props) => {
  const {
    auction,
    errors,
    fuels,
    fuel_indexes,
    hasFuelIndex,
    current_index_price,
    totalFuelVolume,
    updateInformation,
    updateInformationFromCheckbox
  } = props;

  const calculateTotalFuelVolume = () => {
    const fuelQuantity = !!auction.fuel_quantity ? auction.fuel_quantity : 0;
    const startDate = !!auction.start_date ? moment(auction.start_date) : moment();
    const endDate = !!auction.end_date ? moment(auction.end_date) : moment().add(1, 'months');
    const months = endDate.diff(startDate, 'months') + 1;
    const totalFuelVolume = !!fuelQuantity && !!months ? fuelQuantity * months : "—";
    return totalFuelVolume;
  }

  const totalFuelVolumeForInput = (totalFuelVolume) => {
    if (totalFuelVolume == "—") {
      return 0;
    } else {
      return totalFuelVolume;
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
              additionalClasses={'has-margin-bottom-sm'}
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
                    <strong>Your Total Volume: </strong>
                    <input type="hidden" name="auction[total_fuel_volume]" className="qa-auction-total_fuel_volume" value={auction.total_fuel_volume ? aucton.total_fuel_volume : totalFuelVolumeForInput(calculateTotalFuelVolume())} />
                    <span className="qa-auction-total_fuel_volume">{auction.total_fuel_volume ? auction.total_fuel_volume : calculateTotalFuelVolume()}</span> MT
                  </div>
              </div>
            </div>
            { hasFuelIndex &&
              <TermFuelIndexFormSection
                auction={auction}
                errors={errors}
                fuel_indexes={fuel_indexes}
                current_index_price={current_index_price}
                updateInformation={updateInformation} />
            }
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default TermFuelFormSection;
