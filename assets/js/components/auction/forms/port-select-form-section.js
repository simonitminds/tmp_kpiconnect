import React from 'react';
import _ from 'lodash';
import InputField from '../../input-field';

const PortSelectFormSection = (props) => {
  const {
    auction,
    port_id,
    ports,
    selectPort,
    updateInformation
  } = props;

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
    <section className="auction-info is-gray-1">
      <div className="container">
        <div className="content">
          <fieldset>
            <legend className="subtitle is-4" >Port</legend>
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

            {portAgentDisplay()}
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default PortSelectFormSection;
