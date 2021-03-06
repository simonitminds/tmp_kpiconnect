import React from 'react';
import _ from 'lodash';
import InputErrors from './input-errors';

const InputField = ({model, field, labelText, value, errors, opts, onChange, expandedInput, isHorizontal, fuelUnitInput, additionalClasses}) => {

  const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
  const labelDisplay = _.has(opts, 'label') ? opts.label : labelText;
  const type = _.has(opts, 'type') ? opts.type : 'text';
  const step = _.has(opts, 'step') ? opts.step : null;
  const name = _.has(opts, 'name') ? opts.name : field;
  const className = _.has(opts, 'className') ? opts.className : `qa-${model}-${name}`;
  return (
    <div className={`field ${isHorizontal ? 'is-horizontal' : ''} ${additionalClasses ? additionalClasses : ''}`}>
      <div className="field-label">
        <label htmlFor={ !!model ? `${model}_${field}` : name} className={`${labelClass}`}>
        {labelDisplay}
        </label>
      </div>
      <div className="field-body items-start">
        <div className={`control has-margin-right-sm ${expandedInput ? 'is-expanded' : ''}${fuelUnitInput ? ' input__fuel-unit-container' : ''}`}>
          <input
            type={type}
            step={step}
            name={ !!model ? `${model}[${field}]` : name}
            id={`${model}_${name}`}
            className={`input ${className}`}
            defaultValue={value}
            autoComplete="off"
            onChange={onChange}
          />
          { fuelUnitInput && <span className="has-text-gray-3 has-margin-left-sm">MT</span> }
        </div>
        <InputErrors errors={errors} />
      </div>
    </div>
  );
}

export default InputField;
