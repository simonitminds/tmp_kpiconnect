import React from 'react';
import _ from 'lodash';
import InputField from '../../input-field';
import DateInput from '../../date-input';

const PortSelectFormSection = (props) => {
  const {
    auction,
    port_id,
    ports,
    hasDurationAndTerminal,
    selectPort,
    updateInformation,
    updateDate
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

            { hasDurationAndTerminal &&
              <div>
                <InputField
                  className={'qa-auction-terminal'}
                  model={'auction'}
                  field={'terminal'}
                  labelText={'Terminal/Anchorage'}
                  value={auction.terminal}
                  isHorizontal={true}
                  opts={{ labelClass: 'label' }}
                  onChange={updateInformation.bind(this, 'auction.terminal')} />

                <div className="field is-horizontal">
                  <div className="field-label">
                    <label className="label">Start Month</label>
                  </div>
                  <div className="field-body">
                    <DateInput
                      className={'qa-auction-start_month'}
                      value={auction.start_month}
                      model={'auction'}
                      field={'start'}
                      labelText={'Start Month'}
                      onChange={updateDate.bind(this, 'start_month')} />
                  </div>
                </div>


                <div className="field is-horizontal">
                  <div className="field-label">
                    <label className="label">End Month</label>
                  </div>
                  <div className="field-body">
                    <DateInput
                      className={'qa-auction-end_month'}
                      value={auction.end_month}
                      model={'auction'}
                      field={'end'}
                      labelText={'End Month'}
                      onChange={updateDate.bind(this, 'end_month')} />
                  </div>
                </div>
              </div>
            }
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default PortSelectFormSection;
