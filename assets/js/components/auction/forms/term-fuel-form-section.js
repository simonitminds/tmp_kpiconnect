import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import InputField from '../../input-field';
import InputErrors from '../../input-errors';

const TermFuelFormSection = (props) => {
  const { auction, errors, fuels, updateInformation } = props;

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
              labelText={'Fuel Quantity (MT)'}
              value={auction.fuel_quantity}
              errors={errors.fuel_quantity}
              isHorizontal={true}
              opts={{type: 'number'}}
              onChange={updateInformation.bind(this, 'auction.fuel_quantity')}
            />
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default TermFuelFormSection;
