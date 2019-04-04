import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import InputField from '../../../input-field';
import InputErrors from '../../../input-errors';
import DateInput from '../../../date-input';
import DateMonthInput from '../../../date-month-input';

const PortSelectFormSection = (props) => {
  const {
    auction,
    errors,
    port_id,
    ports,
    hasDurationAndTerminal,
    selectPort,
    updateInformation,
    updateDate,
    updateMonth
  } = props;

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

  return (
    <section className="auction-info">
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
                <div className="control has-margin-right-sm">
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
                <InputErrors errors={errors.port_id} />
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
                  errors={errors.terminal}
                  isHorizontal={true}
                  opts={{ labelClass: 'label' }}
                  onChange={updateInformation.bind(this, 'auction.terminal')} />

                <div className="field is-horizontal">
                  <div className="field-label">
                    <label className="label">Start Date</label>
                  </div>
                  <div className="field-body">
                    <input type="hidden" name="auction[start_date]" value={auction.start_date ? moment(auction.start_date).utc() : moment().utc()} className="qa-auction-start_date" />
                    <DateMonthInput
                      value={""}
                      model={'auction'}
                      field={'start_date'}
                      labelText={'Start Month'}
                      onChange={updateMonth.bind(this, 'start_date_date')}
                      className={'has-margin-right-sm'} />
                    <InputErrors errors={errors.start_date} />
                  </div>
                </div>


                <div className="field is-horizontal">
                  <div className="field-label">
                    <label className="label">End Date</label>
                  </div>
                  <div className="field-body">
                    <input type="hidden" name="auction[end_date]" value={auction.end_date ? moment(auction.end_date).utc() : moment().utc()} className="qa-auction-end_date" />
                    <DateMonthInput
                      value={""}
                      model={'auction'}
                      field={'end_date'}
                      labelText={'Start Month'}
                      onChange={updateMonth.bind(this, 'end_date_date')}
                      className={'has-margin-right-sm'} />
                    <InputErrors errors={errors.end_date} />
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
