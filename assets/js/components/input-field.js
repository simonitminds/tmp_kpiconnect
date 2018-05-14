import React from 'react';
import _ from 'lodash';

const InputField = ({model, field, labelText, value, opts, onChange, expandedInput, isHorizontal}) => {
  const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
  const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
  const type = _.has(opts, 'type') ? opts.type : 'text';
  return (
    <div className={`field ${isHorizontal ? 'is-horizontal' : ''}`}>
      <div className="field-label">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
        {labelDisplay}
        </label>
      </div>
      <div className="field-body">
        <div className={`control ${expandedInput ? 'is-expanded' : ''}`}>
          <input
            type={type}
            name={`${model}[${field}]`}
            id={`${model}_${field}`}
            className={`input qa-${model}-${field}`}
            defaultValue={value}
            autoComplete="off"
            onChange={onChange}
          />
        </div>
      </div>
    </div>
  );
}

export default InputField;
