import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import InputField from '../../input-field';

const TermFuelFormSection = (props) => {
  const { auction, fuels, updateInformation } = props;

  return (
    <section className="auction-info"> {/* Fuel info */}
      <div className="container">
        <div className="content">
          <fieldset>
            <legend className="subtitle is-4" >Fuel</legend>
            <div className="field is-horizontal">
              <div className="field-label">
                <label htmlFor="auction_term_fuel_id" className="label">
                  Fuel
                </label>
              </div>
              <div className="field-body">
                <div className="control">
                  <div className="select is-fullwidth">
                    <select
                      id="auction_term_fuel_id"
                      name="auction[term_fuel_id]"
                      className="qa-auction-term_fuel_id"
                      value={auction.term_fuel_id}
                      onChange={updateInformation.bind(this, 'auction.term_fuel_id')}
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
              </div>
            </div>

            <InputField
              model={'auction'}
              field={'term_fuel_quantity'}
              labelText={'Fuel Quantity (MT)'}
              value={auction.term_fuel_quantity}
              isHorizontal={true}
              opts={{type: 'number'}}
              onChange={updateInformation.bind(this, 'auction.term_fuel_quantity')}
            />
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default TermFuelFormSection;
