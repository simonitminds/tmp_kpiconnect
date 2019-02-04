import React from 'react';
import _ from 'lodash';
import InputErrors from './input-errors';

const InputField = ({model, field, labelText, value, errors, opts, onChange, expandedInput, isHorizontal}) => {
  const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
  const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
  const type = _.has(opts, 'type') ? opts.type : 'text';
  const name = _.has(opts, 'name') ? opts.name : field;
  const className = _.has(opts, 'className') ? opts.className : `qa-${model}-${name}`;
  return (
    <div className={`field ${isHorizontal ? 'is-horizontal' : ''}`}>
      <div className="field-label">
        <label htmlFor={`${model}_${field}`} className={`${labelClass} is-capitalized`}>
        {labelDisplay}
        </label>
      </div>
      <div className="field-body">
        <div className={`control ${expandedInput ? 'is-expanded' : ''}`}>
          <input
            type={type}
            name={`${model}[${field}]`}
            id={`${model}_${name}`}
            className={`input ${className}`}
            defaultValue={value}
            autoComplete="off"
            onChange={onChange}
          />
        </div>
        <InputErrors errors={errors} />
      </div>
    </div>
  );
}

export default InputField;
