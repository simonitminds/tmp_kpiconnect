import React from 'react';
import _ from 'lodash';
import InputField from '../../../input-field';
import InputErrors from '../../../input-errors';

const TermFuelIndexFormSection = (props) => {
  const {
    auction,
    errors,
    fuels,
    fuel_indexes,
    current_index_price,
    updateInformation
  } = props;

  return (
    <React.Fragment>
      <div className="field is-horizontal">
          <div className="field-label">
            <label htmlFor="auction_fuel_index_id" className="label">
              Fuel Index
            </label>
          </div>
          <div className="field-body">
            <div className="control has-margin-right-sm">
              <div className="select is-fullwidth">
                <select
                  id="fuel_index_id"
                  name="auction[fuel_index_id]"
                  className="qa-auction-select-fuel_index"
                  value={auction.fuel_index_id}
                  onChange={updateInformation.bind(this, 'auction.fuel_index_id')}
                >
                  <option disabled value="">
                    Please select
                  </option>
                  {_.map(fuel_indexes, fuelIndex => (
                    <option key={fuelIndex.id} value={fuelIndex.id}>
                      {fuelIndex.port.name} | {fuelIndex.name} | {fuelIndex.fuel.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <InputErrors errors={errors.fuel_index_id} />
          </div>
        </div>
      { window.isAdmin &&
        <InputField
          model={'auction'}
          field={'current_index_price'}
          labelText={'Current Index Price'}
          value={current_index_price}
          errors={errors.current_index_price}
          isHorizontal={true}
          opts={{type: 'number', step: '0.01'}}
          onChange={updateInformation.bind(this, 'auction.current_index_price')} />
        }
    </React.Fragment>
  );
}
export default TermFuelIndexFormSection;
