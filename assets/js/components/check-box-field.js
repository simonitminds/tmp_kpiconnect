import React from 'react';
import _ from 'lodash';

const CheckBoxField = ({model, field, labelText, defaultChecked, onChange, opts = {}}) => {
  const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
  const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
  const readOnly = _.has(opts, 'readOnly') ? opts.readOnly : false;

  return (
    <div className="field has-margin-bottom-none">
      <div className="control">
        <input name={`${model}[${field}]`} type="hidden" value="false" />
        <input
          className={`checkbox qa-${model}-${field}`}
          id={`${field}`}
          name={`${model}[${field}]`}
          type="checkbox"
          defaultChecked={defaultChecked}
          onChange={onChange}
          {...{disabled: readOnly}}
        />
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
      </div>
    </div>
  );
}

export default CheckBoxField;
